# Dokumentasi Lengkap API — WalletShare (Emran Uang)

Selamat datang di dokumentasi API resmi untuk aplikasi **WalletShare**. API ini dibangun menggunakan Node.js, Express, Prisma, dan PostgreSQL.

## Informasi Umum
- **Base URL Lokal:** `http://localhost:3000/api`
- **Format Data:** JSON (baik untuk request body maupun response)
- **Header Global:**
  - `Content-Type: application/json`
  - `Authorization: Bearer <JWT_ACCESS_TOKEN>` (untuk route terproteksi)

---

## Ringkasan Endpoints

| Grup API | Endpoint | Method | Deskripsi | Proteksi |
| :--- | :--- | :---: | :--- | :---: |
| **Auth** | `/auth/config` | `GET` | Ambil public auth config (Google Client ID) | Publik |
| | `/auth/register` | `POST` | Pendaftaran akun baru via email/password | Publik |
| | `/auth/login` | `POST` | Masuk ke akun via email/password | Publik |
| | `/auth/google` | `POST` | Masuk/daftar menggunakan Google Auth | Publik |
| | `/auth/refresh` | `POST` | Perbarui access token menggunakan refresh token | Publik |
| | `/auth/me` | `GET` | Ambil data profil user yang aktif saat ini | JWT |
| **Wallets** | `/wallets` | `GET` | List semua dompet (Personal & Shared) | JWT |
| | `/wallets/:id` | `PATCH` | Perbarui properti wallet (nama, limit budget) | JWT |
| **Expenses** | `/expenses` | `GET` | List pengeluaran dengan filter | JWT + Wallet |
| | `/expenses/:id` | `GET` | Dapatkan detail satu pengeluaran | JWT + Wallet |
| | `/expenses` | `POST` | Catat pengeluaran baru | JWT + Wallet |
| | `/expenses/:id` | `PUT` | Perbarui catatan pengeluaran | JWT + Wallet |
| | `/expenses/:id` | `DELETE` | Hapus catatan pengeluaran | JWT + Wallet |
| **Reminders**| `/reminders` | `GET` | List tagihan / pengingat pembayaran | JWT + Wallet |
| | `/reminders` | `POST` | Buat pengingat tagihan baru | JWT + Wallet |
| | `/reminders/:id` | `PUT` | Perbarui data pengingat tagihan | JWT + Wallet |
| | `/reminders/:id` | `DELETE` | Batalkan pengingat tagihan (soft delete) | JWT + Wallet |
| **Categories**| `/categories` | `GET` | Dapatkan kategori default & kustom user | JWT |
| | `/categories` | `POST` | Buat kategori kustom baru | JWT |
| | `/categories/:id` | `PUT` | Perbarui kategori kustom | JWT |
| | `/categories/:id` | `DELETE` | Nonaktifkan kategori kustom (soft delete) | JWT |
| **Analytics**| `/analytics/compare` | `GET` | Analisis komparasi spending antar bulan | JWT + Wallet |
| | `/analytics/breakdown`| `GET` | Breakdown pengeluaran berdasarkan kategori | JWT + Wallet |
| | `/analytics/trend` | `GET` | Trend pengeluaran harian sepanjang bulan | JWT + Wallet |
| **Sharing** | `/sharing/groups` | `GET` | List grup bersama dan undangan pending | JWT |
| | `/sharing/invite` | `POST` | Kirim undangan sharing data (grup baru) | JWT |
| | `/sharing/invite/:id/accept`| `POST` | Terima undangan & buat wallet bersama | JWT |
| | `/sharing/invite/:id/reject`| `POST` | Tolak undangan | JWT |
| | `/sharing/groups/:id/archive`| `POST` | Arsipkan grup bersama (soft delete) | JWT |
| | `/sharing/groups/:id/leave`| `POST` | Keluar dari grup bersama | JWT |

---

## Detail Endpoints

### 1. Autentikasi (`/auth`)

#### `GET /auth/config`
Mengambil konfigurasi publik Google Client ID.
- **Request:** (Tidak memerlukan body & auth)
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Auth configuration retrieved successfully",
  "data": {
    "googleClientId": "123456789-example.apps.googleusercontent.com"
  }
}
```

#### `POST /auth/register`
Mendaftarkan akun baru menggunakan email.
- **Body Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "displayName": "Emran"
}
```
- **Response (210 Created):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": "cuid-user-123",
      "email": "user@example.com",
      "displayName": "Emran",
      "avatarUrl": null,
      "authProvider": "EMAIL",
      "createdAt": "2026-06-29T10:00:00.000Z"
    },
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG..."
  }
}
```

#### `POST /auth/login`
Masuk menggunakan email dan password.
- **Body Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "cuid-user-123",
      "email": "user@example.com",
      "displayName": "Emran",
      "avatarUrl": null,
      "authProvider": "EMAIL",
      "createdAt": "2026-06-29T10:00:00.000Z"
    },
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG..."
  }
}
```

#### `POST /auth/google`
Masuk atau daftar otomatis menggunakan Google OAuth.
- **Body Request:** (Sediakan salah satu)
```json
{
  "idToken": "google-id-token",
  "accessToken": "google-access-token"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Google login successful",
  "data": {
    "user": {
      "id": "cuid-user-123",
      "email": "user@example.com",
      "displayName": "Emran",
      "avatarUrl": "https://lh3.googleusercontent.com/...",
      "authProvider": "GOOGLE",
      "createdAt": "2026-06-29T10:00:00.000Z"
    },
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG...",
    "isNewUser": false
  }
}
```

#### `POST /auth/refresh`
Memperbarui access token yang kedaluwarsa.
- **Body Request:**
```json
{
  "refreshToken": "refresh-token-jwt"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "new-access-token-jwt",
    "refreshToken": "new-refresh-token-jwt"
  }
}
```

#### `GET /auth/me`
Mengambil detail informasi user saat ini beserta daftar dompet (wallets) dan grup bersama yang diikuti.
- **Header:** `Authorization: Bearer <token>`
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": "cuid-user-123",
    "email": "user@example.com",
    "displayName": "Emran",
    "avatarUrl": null,
    "authProvider": "EMAIL",
    "createdAt": "2026-06-29T10:00:00.000Z",
    "wallets": [
      {
        "id": "personal-wallet-id",
        "name": "Personal Wallet",
        "type": "PERSONAL",
        "currency": "IDR",
        "groupId": null
      }
    ],
    "sharedGroups": []
  }
}
```

---

### 2. Dompet (`/wallets`)

#### `GET /wallets`
Mengambil seluruh daftar dompet milik user (Personal) dan dompet dari grup bersama yang aktif (Shared).
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "personal": [
      {
        "id": "personal-wallet-id",
        "name": "Personal Wallet",
        "type": "PERSONAL",
        "currency": "IDR",
        "dailyBudget": "50000.00",
        "createdAt": "2026-06-29T10:00:00.000Z",
        "_count": {
          "expenses": 12,
          "billReminders": 2
        }
      }
    ],
    "shared": [
      {
        "id": "shared-wallet-id",
        "name": "Keluarga Emran",
        "type": "SHARED",
        "currency": "IDR",
        "dailyBudget": null,
        "createdAt": "2026-06-29T10:05:00.000Z",
        "_count": {
          "expenses": 4,
          "billReminders": 0
        },
        "group": {
          "id": "group-cuid-123",
          "name": "Keluarga Emran",
          "members": [
            {
              "id": "user-cuid-abc",
              "displayName": "Sarah",
              "avatarUrl": null
            }
          ]
        }
      }
    ]
  }
}
```

#### `PATCH /wallets/:id`
Memperbarui detail dompet (seperti limit harian atau nama).
- **Body Request:** (Semua field opsional)
```json
{
  "name": "Dompet Harian",
  "dailyBudget": 75000
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": "personal-wallet-id",
    "name": "Dompet Harian",
    "type": "PERSONAL",
    "currency": "IDR",
    "dailyBudget": 75000.00,
    "createdAt": "2026-06-29T10:00:00.000Z",
    "updatedAt": "2026-06-29T10:30:00.000Z"
  }
}
```

---

### 3. Pengeluaran (`/expenses`)
> **Catatan:** Seluruh endpoint di bawah `/expenses` memerlukan validasi `walletId` (dikirim via Query Parameter atau Request Body) guna memastikan pengguna memiliki hak akses terhadap wallet tersebut.

#### `GET /expenses`
Mengambil semua catatan transaksi pengeluaran pada wallet tertentu dengan filter dan pagination.
- **Query Parameters:**
  - `walletId` (Wajib): ID Dompet
  - `timeframe`: `daily` | `monthly` | `yearly` (opsional)
  - `date`: Format `YYYY-MM-DD` atau `YYYY-MM` (opsional)
  - `type`: `ROUTINE` | `NON_ROUTINE` (opsional)
  - `categoryId`: ID Kategori (opsional)
  - `page`: Nomor halaman (default: 1)
  - `limit`: Jumlah per halaman (default: 20)
- **Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "expense-id-111",
      "amount": "15000.00",
      "description": "Kopi Pagi",
      "date": "2026-06-29T08:30:00.000Z",
      "type": "NON_ROUTINE",
      "userId": "cuid-user-123",
      "walletId": "personal-wallet-id",
      "categoryId": "category-id-food",
      "billReminderId": null,
      "createdAt": "2026-06-29T08:31:00.000Z",
      "category": {
        "id": "category-id-food",
        "name": "Food & Drinks",
        "icon": "restaurant",
        "color": "#FF6B6B"
      },
      "user": {
        "id": "cuid-user-123",
        "displayName": "Emran",
        "avatarUrl": null
      }
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1
  }
}
```

#### `POST /expenses`
Mencatat transaksi pengeluaran baru.
- **Body Request:**
```json
{
  "amount": 25000,
  "description": "Beli Cemilan",
  "date": "2026-06-29T10:15:00.000Z",
  "type": "NON_ROUTINE",
  "categoryId": "category-id-food",
  "walletId": "personal-wallet-id"
}
```
- **Response (210 Created):**
```json
{
  "success": true,
  "message": "Expense created",
  "data": {
    "id": "expense-id-222",
    "amount": 25000,
    "description": "Beli Cemilan",
    "date": "2026-06-29T10:15:00.000Z",
    "type": "NON_ROUTINE",
    "userId": "cuid-user-123",
    "walletId": "personal-wallet-id",
    "categoryId": "category-id-food",
    "createdAt": "2026-06-29T10:16:00.000Z",
    "category": {
      "id": "category-id-food",
      "name": "Food & Drinks",
      "icon": "restaurant",
      "color": "#FF6B6B"
    },
    "user": {
      "id": "cuid-user-123",
      "displayName": "Emran"
    }
  }
}
```

#### `PUT /expenses/:id`
Memperbarui transaksi pengeluaran yang telah dicatat (hanya bisa dilakukan oleh pembuat transaksi).
- **Body Request:** (Wajib menyertakan `walletId`)
```json
{
  "walletId": "personal-wallet-id",
  "amount": 30000,
  "description": "Beli Cemilan (Premium)"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Expense updated",
  "data": { ... }
}
```

#### `DELETE /expenses/:id`
Menghapus catatan transaksi pengeluaran (hanya pembuat transaksi).
- **Query Parameter:** `?walletId=personal-wallet-id`
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Expense deleted",
  "data": null
}
```

---

### 4. Tagihan & Pengingat (`/reminders`)

#### `GET /reminders`
Mengambil semua pengingat tagihan aktif pada dompet tertentu.
- **Query Parameters:**
  - `walletId` (Wajib)
  - `status`: `ACTIVE` | `SNOOZED` | `COMPLETED` | `CANCELLED`
  - `upcoming`: Jumlah hari ke depan (misal `7` untuk tagihan 7 hari ke depan)
- **Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "reminder-id-123",
      "title": "Netflix Premium",
      "amount": "186000.00",
      "dueDate": "2026-07-15T00:00:00.000Z",
      "periodicity": "MONTHLY",
      "status": "ACTIVE",
      "userId": "cuid-user-123",
      "walletId": "personal-wallet-id",
      "categoryId": "category-id-sub",
      "notifyDaysBefore": 3,
      "autoLogExpense": true,
      "category": { ... },
      "wallet": { ... }
    }
  ]
}
```

#### `POST /reminders`
Membuat pengingat tagihan baru.
- **Body Request:**
```json
{
  "title": "Listrik Bulanan",
  "amount": 250000,
  "dueDate": "2026-07-05T00:00:00.000Z",
  "periodicity": "MONTHLY",
  "categoryId": "category-id-utility",
  "walletId": "personal-wallet-id",
  "notifyDaysBefore": 5,
  "autoLogExpense": false
}
```
- **Response (210 Created):**
```json
{
  "success": true,
  "message": "Bill reminder created",
  "data": { ... }
}
```

---

### 5. Kategori (`/categories`)

#### `GET /categories`
Mendapatkan semua kategori sistem bawaan (default) dan kategori kustom buatan user saat ini.
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": [
    {
      "id": "category-id-food",
      "name": "Food & Drinks",
      "icon": "restaurant",
      "color": "#FF6B6B",
      "isDefault": true,
      "userId": null
    },
    {
      "id": "category-custom-id",
      "name": "Hobi Gundam",
      "icon": "smart_toy",
      "color": "#3498DB",
      "isDefault": false,
      "userId": "cuid-user-123"
    }
  ]
}
```

#### `POST /categories`
Membuat kategori kustom baru.
- **Body Request:**
```json
{
  "name": "Kopi & Kafe",
  "icon": "local_cafe",
  "color": "#8E44AD"
}
```
- **Response (210 Created):**
```json
{
  "success": true,
  "message": "Category created",
  "data": { ... }
}
```

---

### 6. Analisis & Grafik (`/analytics`)

#### `GET /analytics/compare`
Membandingkan grafik spending bulan ini dengan bulan-bulan sebelumnya.
- **Query Parameters:**
  - `walletId` (Wajib)
  - `date`: Bulan patokan (opsional, default: sekarang)
  - `months`: Jumlah bulan pembanding (default: 2, max: 12)
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "months": [
      {
        "month": "2026-06",
        "total": 450000,
        "count": 14,
        "byCategory": [ ... ],
        "byType": [ ... ]
      },
      {
        "month": "2026-05",
        "total": 520000,
        "count": 18,
        "byCategory": [ ... ],
        "byType": [ ... ]
      }
    ],
    "summary": {
      "currentMonth": "2026-06",
      "previousMonth": "2026-05",
      "currentTotal": 450000,
      "previousTotal": 520000,
      "changePercent": -13.46,
      "direction": "decreased"
    }
  }
}
```

#### `GET /analytics/breakdown`
Mendapatkan persentase kontribusi pengeluaran per kategori.
- **Query Parameters:**
  - `walletId` (Wajib)
  - `timeframe`: `daily` | `monthly` | `yearly` (default: `monthly`)
  - `date`: Target range
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "range": {
      "start": "2026-06-01T00:00:00.000Z",
      "end": "2026-06-30T23:59:59.999Z"
    },
    "grandTotal": 450000,
    "categories": [
      {
        "category": { "name": "Food & Drinks", "color": "#FF6B6B" },
        "total": 300000,
        "count": 10,
        "percentage": 66.67
      },
      {
        "category": { "name": "Transport", "color": "#45B7D1" },
        "total": 150000,
        "count": 4,
        "percentage": 33.33
      }
    ]
  }
}
```

---

### 7. Data Bersama (`/sharing`)

#### `GET /sharing/groups`
Melihat daftar grup bersama aktif yang diikuti user beserta daftar undangan masuk/keluar berstatus `PENDING`.
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "groups": [
      {
        "group": {
          "id": "group-123",
          "name": "Keluarga Emran",
          "status": "ACTIVE",
          "members": [
            {
              "role": "OWNER",
              "user": { "displayName": "Emran", "email": "me@example.com" }
            },
            {
              "role": "MEMBER",
              "user": { "displayName": "Sarah", "email": "sarah@walletshare.com" }
            }
          ]
        },
        "myRole": "OWNER"
      }
    ],
    "pendingInvites": []
  }
}
```

#### `POST /sharing/invite`
Kirim undangan sharing data dan otomatis membuat draft grup baru.
- **Body Request:**
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
  "message": "Undangan terkirim...",
  "data": {
    "invite": { "id": "invite-456", "status": "PENDING" },
    "group": { "id": "group-123", "name": "Keluarga Emran" },
    "targetUserFound": true
  }
}
```

#### `POST /sharing/invite/:id/accept`
Menerima undangan sharing data dan secara otomatis membuat/menghubungkan dompet bersama (`SHARED` wallet).
- **Path Parameter:** `:id` (ID Undangan)
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Undangan diterima — data bersama aktif!",
  "data": {
    "group": { "id": "group-123", "status": "ACTIVE" },
    "sharedWallet": { "id": "wallet-shared", "type": "SHARED" }
  }
}
```

#### `POST /sharing/invite/:id/reject`
Menolak undangan sharing data.
- **Path Parameter:** `:id` (ID Undangan)
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Undangan ditolak",
  "data": null
}
```

#### `POST /sharing/groups/:id/archive`
Mengarsipkan grup bersama dan menyembunyikan dompet bersama dari dashboard utama. Hanya boleh dilakukan oleh `OWNER` grup.
- **Path Parameter:** `:id` (ID Grup)
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Grup diarsipkan. Riwayat data bersama tetap tersimpan.",
  "data": null
}
```

#### `POST /sharing/groups/:id/leave`
Meninggalkan grup bersama. Apabila user yang keluar adalah pemilik (`OWNER`), hak kepemilikan dialihkan otomatis ke anggota berikutnya. Jika tidak ada anggota tersisa, grup otomatis diarsipkan.
- **Path Parameter:** `:id` (ID Grup)
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Anda telah keluar dari grup.",
  "data": null
}
```
