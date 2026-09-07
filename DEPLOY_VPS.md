# Panduan Deploy Emran Uang API ke VPS dengan Docker Compose

Panduan lengkap langkah demi langkah untuk mendistribusikan backend **Emran Uang API** ke Virtual Private Server (VPS) berbasis Linux (Ubuntu / Debian) menggunakan Docker dan Docker Compose.

---

## Daftar Isi

1. [Prasyarat](#1-prasyarat)
2. [Instalasi Docker & Docker Compose di VPS](#2-instalasi-docker--docker-compose-di-vps)
3. [Clone Repository & Konfigurasi .env](#3-clone-repository--konfigurasi-env)
4. [Menjalankan Aplikasi](#4-menjalankan-aplikasi)
5. [Setup Domain & SSL Gratis (Nginx + Certbot)](#5-setup-domain--ssl-gratis-nginx--certbot)
6. [Setup Cron Job Pengingat Tagihan (Bill Reminders)](#6-setup-cron-job-pengingat-tagihan-bill-reminders)
7. [Menghubungkan Aplikasi Flutter Mobile](#7-menghubungkan-aplikasi-flutter-mobile)
8. [Perawatan & Update Aplikasi](#8-perawatan--update-aplikasi)

---

## 1. Prasyarat

- VPS dengan OS **Ubuntu 22.04 / 24.04 LTS** atau **Debian 12**
- Akses SSH ke VPS (`ssh root@ip-vps-anda`)
- RAM minimal 1 GB (disarankan 2 GB jika menjalankan PostgreSQL di dalam VPS)
- Domain / Subdomain yang sudah diarahkan (DNS A Record) ke IP Publik VPS Anda (misalnya: `api.domainanda.com`)

---

## 2. Instalasi Docker & Docker Compose di VPS

Masuk ke VPS Anda via terminal SSH, lalu jalankan perintah berikut:

```bash
# 1. Update paket sistem
sudo apt update && sudo apt upgrade -y

# 2. Install dependensi
sudo apt install -y curl git ufw

# 3. Install Docker menggunakan skrip resmi Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 4. Verifikasi instalasi Docker & Docker Compose
docker --version
docker compose version
```

Aktifkan firewall dasar untuk keamanan:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

---

## 3. Clone Repository & Konfigurasi `.env`

Di server VPS Anda:

```bash
# 1. Masuk ke direktori aplikasi
mkdir -p /var/www && cd /var/www

# 2. Clone repository Anda
git clone https://github.com/username/emran-uang.git
cd emran-uang

# 3. Salin contoh file konfigurasi environment
cp .env.docker.example .env

# 4. Edit file .env
nano .env
```

### Konfigurasi penting pada `.env`:

#### A. Database (Pilih salah satu):

- **Opsi 1: PostgreSQL Lokal di Docker (Bawaan)**
  Biarkan konfigurasi default:
  ```env
  DATABASE_URL="postgresql://postgres:password_rahasia_db@postgres:5432/emran_uang?schema=public"
  DIRECT_URL="postgresql://postgres:password_rahasia_db@postgres:5432/emran_uang?schema=public"
  POSTGRES_PASSWORD="password_rahasia_db"
  ```
- **Opsi 2: PostgreSQL Cloud (Neon)**
  Jika tetap ingin menggunakan Neon:
  ```env
  DATABASE_URL="postgresql://user:password@ep-xxx.region.aws.neon.tech:5432/emran_uang?sslmode=require&pgbouncer=true"
  DIRECT_URL="postgresql://user:password@ep-xxx.region.aws.neon.tech:5432/emran_uang?sslmode=require"
  ```

#### B. JWT Secret:

Buat string acak di terminal dengan:

```bash
openssl rand -base64 32
```

Lalu tempel hasilnya ke `JWT_SECRET` dan `JWT_REFRESH_SECRET` di `.env`.

#### C. Firebase Service Account (Opsional untuk Push Notifikasi):

Jika Anda memiliki file `firebase-service-account.json`, Anda bisa menyalin isinya menjadi string satu baris di variabel:

```env
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account", ...}'
```

Simpan file dengan menekan `CTRL + O`, lalu `Enter`, lalu keluar dengan `CTRL + X`.

---

## 4. Menjalankan Aplikasi

Jalankan container menggunakan Docker Compose:

```bash
# Build dan jalankan di latar belakang
docker compose up -d --build
```

### Periksa Status Container:

```bash
# Cek apakah container berjalan lancar
docker compose ps

# Cek log aplikasi untuk melihat sinkronisasi Prisma & server start
docker compose logs -f api
```

Saat pertama kali berjalan, container akan otomatis menjalankan `prisma db push` untuk membuat tabel dan skema database secara otomatis.

### Tes Endpoint API:

```bash
curl http://localhost:3000/api
```

Output yang diharapkan:

```json
{"success":true,"message":"WalletShare API is running!","version":"1.0.0",...}
```

---

## 5. Setup Domain & SSL Gratis (Nginx + Certbot)

Agar aplikasi dapat diakses melalui HTTPS secara aman (`https://api.domainanda.com`), kita gunakan Nginx sebagai reverse proxy.

### 1. Install Nginx dan Certbot:

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### 2. Buat Konfigurasi Nginx:

```bash
sudo nano /etc/nginx/sites-available/emran-api
```

Tempel konfigurasi berikut (ganti `api.domainanda.com` dengan domain Anda):

```nginx
server {
    server_name api.domainanda.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### 3. Aktifkan Konfigurasi & Restart Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/emran-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Pasang Sertifikat SSL (Let's Encrypt / HTTPS):

```bash
sudo certbot --nginx -d api.domainanda.com
```

Ikuti petunjuk di layar (masukkan email dan setujui ToS). Certbot akan otomatis mengonfigurasi SSL dan mengatur auto-renewal setiap 90 hari.

---

## 6. Setup Cron Job Pengingat Tagihan (Bill Reminders)

Di Vercel sebelumnya mungkin menggunakan Vercel Cron. Di VPS, Anda bisa menggunakan `cron` bawaan Linux.

Jalankan perintah:

```bash
crontab -e
```

Tambahkan baris berikut di bagian paling bawah (contoh berjalan setiap hari pukul 08:00 pagi WIB / 01:00 UTC):

```bash
0 1 * * * curl -X POST https://wallet.libertysky.icu/api/notifications/cron/bill-reminders -H "Authorization: Bearer b5aacfb3f08290cc81e8f691aa598c48f0535e8795412efdfd29be1d81fa8965" >> /var/log/emran_cron.log 2>&1
```

---

## 7. Menghubungkan Aplikasi Flutter Mobile

Buka project aplikasi Flutter di komputer lokal Anda:

1. Buka file `mobile/.env`
2. Ubah `API_URL` menjadi URL domain VPS Anda:
   ```env
   API_URL=https://api.domainanda.com/api
   ```
3. Lakukan build aplikasi:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

---

## 8. Perawatan & Update Aplikasi

Jika ada pembaruan kode baru dari git:

```bash
cd /var/www/emran-uang

# 1. Tarik kode terbaru
git pull origin main

# 2. Rebuild & restart container tanpa downtime lama
docker compose up -d --build

# 3. Periksa log
docker compose logs -f api
```

### Perintah Penting Docker Compose:

- **Melihat log real-time**: `docker compose logs -f api`
- **Restart container**: `docker compose restart api`
- **Menghentikan aplikasi**: `docker compose down`
- **Melihat status & resource**: `docker compose ps` atau `docker stats`
- **Menjalankan Prisma Studio di VPS**:
  ```bash
  docker compose exec api npx prisma studio --port 5555 --hostname 0.0.0.0
  ```
