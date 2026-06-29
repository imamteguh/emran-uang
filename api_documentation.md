# Dokumentasi API — Share Data (Data Bersama)

Dokumentasi ini menjelaskan endpoints API `/api/sharing` yang menggantikan sistem `/api/couples`. Sistem baru ini memungkinkan pengguna untuk membuat grup bersama (Shared Group), mengundang banyak pengguna lain untuk saling berbagi pengeluaran dan tagihan, menerima/menolak undangan, serta keluar atau mengarsipkan grup bersama.

## Base URL
- **Lokal:** `http://localhost:3000/api`
- **Produksi:** `/api` (sesuai konfigurasi Vercel rewrite)

## Autentikasi
Semua request ke endpoint ini wajib menyertakan header autentikasi JWT:
```http
Authorization: Bearer <jwt_access_token>
```

---

## 1. Dapatkan Daftar Grup Bersama & Undangan Pending
Mengambil seluruh grup bersama aktif yang diikuti oleh user saat ini beserta daftar undangan masuk atau keluar yang berstatus `PENDING`.

- **Method:** `GET`
- **Path:** `/sharing/groups`
- **Header:** `Authorization: Bearer <token>`
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "groups": [
      {
        "group": {
          "id": "group-cuid-123",
          "name": "Keluarga Emran",
          "status": "ACTIVE",
          "createdAt": "2026-06-29T10:00:00.000Z",
          "updatedAt": "2026-06-29T10:05:00.000Z",
          "archivedAt": null,
          "members": [
            {
              "id": "member-cuid-999",
              "role": "MEMBER",
              "joinedAt": "2026-06-29T10:05:00.000Z",
              "user": {
                "id": "user-cuid-abc",
                "displayName": "Sarah",
                "avatarUrl": "https://...",
                "email": "sarah@walletshare.com"
              }
            }
          ],
          "sharedWallets": [
            {
              "id": "wallet-cuid-xyz",
              "name": "Keluarga Emran",
              "currency": "IDR"
            }
          ]
        },
        "myRole": "OWNER"
      }
    ],
    "pendingInvites": [
      {
        "id": "invite-cuid-456",
        "status": "PENDING",
        "senderId": "user-cuid-xyz",
        "receiverId": "user-cuid-my-id",
        "receiverEmail": "me@walletshare.com",
        "groupId": "group-cuid-999",
        "expiresAt": "2026-07-06T10:00:00.000Z",
        "createdAt": "2026-06-29T10:00:00.000Z",
        "updatedAt": "2026-06-29T10:00:00.000Z",
        "sender": {
          "id": "user-cuid-xyz",
          "displayName": "Budi",
          "avatarUrl": null
        },
        "group": {
          "id": "group-cuid-999",
          "name": "Patungan Kost"
        }
      }
    ]
  }
}
```

---

## 2. Kirim Undangan Sharing Data
Membuat grup bersama baru dan mengirim undangan kontribusi ke alamat email target. Jika email target belum terdaftar di sistem, undangan tetap dibuat dan akan ditautkan setelah user mendaftar.

- **Method:** `POST`
- **Path:** `/sharing/invite`
- **Header:** `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "email": "sarah@walletshare.com",
  "groupName": "Keluarga Emran"
}
```
- **Response (210 Created):**
```json
{
  "success": true,
  "message": "Undangan terkirim ke user yang sudah terdaftar",
  "data": {
    "invite": {
      "id": "invite-cuid-456",
      "status": "PENDING",
      "senderId": "user-cuid-my-id",
      "receiverId": "user-cuid-sarah-id",
      "receiverEmail": "sarah@walletshare.com",
      "groupId": "group-cuid-123",
      "expiresAt": "2026-07-06T03:21:18.000Z",
      "createdAt": "2026-06-29T03:21:18.000Z",
      "updatedAt": "2026-06-29T03:21:18.000Z"
    },
    "group": {
      "id": "group-cuid-123",
      "name": "Keluarga Emran",
      "status": "PENDING",
      "createdAt": "2026-06-29T03:21:18.000Z",
      "updatedAt": "2026-06-29T03:21:18.000Z",
      "archivedAt": null
    },
    "targetUserFound": true
  }
}
```
- **Error Responses:**
  - `400 Bad Request`: `Email tujuan wajib diisi` atau `Tidak bisa mengundang diri sendiri`
  - `409 Conflict`: `Anda sudah memiliki undangan pending ke email ini. Batalkan dulu sebelum mengirim yang baru.`

---

## 3. Menerima Undangan Sharing Data
Menyetujui undangan sharing data. Aksi ini akan menambahkan user saat ini ke dalam anggota grup tersebut, mengubah status grup menjadi `ACTIVE`, dan mengaktifkan/membuat dompet bersama (`SHARED` wallet).

- **Method:** `POST`
- **Path:** `/sharing/invite/:id/accept`
- **Header:** `Authorization: Bearer <token>`
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Undangan diterima — data bersama aktif!",
  "data": {
    "group": {
      "id": "group-cuid-123",
      "name": "Keluarga Emran",
      "status": "ACTIVE",
      "createdAt": "2026-06-29T03:21:18.000Z",
      "updatedAt": "2026-06-29T03:22:00.000Z",
      "archivedAt": null
    },
    "sharedWallet": {
      "id": "wallet-cuid-shared",
      "name": "Keluarga Emran",
      "type": "SHARED",
      "currency": "IDR",
      "dailyBudget": null,
      "userId": null,
      "groupId": "group-cuid-123",
      "createdAt": "2026-06-29T03:22:00.000Z",
      "updatedAt": "2026-06-29T03:22:00.000Z"
    }
  }
}
```
- **Error Responses:**
  - `400 Bad Request`: `Undangan sudah accepted/rejected`, `Tidak bisa menerima undangan sendiri`
  - `403 Forbidden`: `Undangan ini bukan untuk Anda`
  - `404 Not Found`: `Undangan tidak ditemukan`
  - `409 Conflict`: `Anda sudah menjadi anggota grup ini`
  - `410 Gone`: `Undangan sudah kedaluwarsa`

---

## 4. Menolak Undangan Sharing Data
Menolak undangan sharing data yang dikirimkan kepada user saat ini. Apabila grup tersebut baru dibuat dan belum ada anggota lain yang bergabung selain pembuat (owner), grup tersebut akan dihapus secara otomatis.

- **Method:** `POST`
- **Path:** `/sharing/invite/:id/reject`
- **Header:** `Authorization: Bearer <token>`
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Undangan ditolak",
  "data": null
}
```
- **Error Responses:**
  - `400 Bad Request`: `Undangan sudah accepted/rejected`
  - `403 Forbidden`: `Undangan ini bukan untuk Anda`
  - `404 Not Found`: `Undangan tidak ditemukan`

---

## 5. Mengarsipkan Grup Bersama (Soft Delete)
Mengubah status grup menjadi `ARCHIVED` dan menonaktifkan dompet bersama yang terafiliasi. Riwayat transaksi pengeluaran dan tagihan di dalam dompet tersebut tetap aman tersimpan di database untuk keperluan arsip. Hanya pemilik grup (`OWNER`) yang diijinkan melakukan aksi ini.

- **Method:** `POST`
- **Path:** `/sharing/groups/:id/archive`
- **Header:** `Authorization: Bearer <token>`
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Grup diarsipkan. Riwayat data bersama tetap tersimpan.",
  "data": null
}
```
- **Error Responses:**
  - `403 Forbidden`: `Hanya pemilik grup yang bisa mengarsipkan`
  - `404 Not Found`: `Anda bukan anggota grup ini atau grup tidak aktif`

---

## 6. Keluar dari Grup Bersama
Aksi untuk meninggalkan grup bersama. Jika user saat ini merupakan pembuat grup (`OWNER`), kepemilikan grup (`OWNER` role) akan dialihkan secara otomatis ke anggota berikutnya yang terdaftar di grup tersebut. Jika user tersebut merupakan anggota terakhir di grup tersebut, grup akan otomatis diarsipkan (`ARCHIVED`).

- **Method:** `POST`
- **Path:** `/sharing/groups/:id/leave`
- **Header:** `Authorization: Bearer <token>`
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Anda telah keluar dari grup.",
  "data": null
}
```
- **Error Responses:**
  - `404 Not Found`: `Anda bukan anggota grup ini`
