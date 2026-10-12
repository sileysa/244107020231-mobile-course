
---

# 2️⃣ `docs/ai-output.md`

Nah, ini **output awal AI**. Karena tugas meminta output AI disimpan, kita dokumentasikan jawaban awal yang menjadi bahan perbandingan.

```md
# AI Initial Output

## Ringkasan Rekomendasi AI

| Storage | Preferensi | Catatan |
|---|---|---|
| SharedPreferences | Sangat cocok | Tidak direkomendasikan |
| Hive | Cocok | Cocok untuk data lokal sederhana |
| sqflite / SQLite | Bisa | Sangat cocok |
| Drift | Bisa | Sangat cocok untuk kebutuhan database kompleks |

## Perbandingan

### SharedPreferences

SharedPreferences menggunakan sistem key-value sehingga cocok untuk
menyimpan data sederhana seperti:

- boolean
- string
- integer
- double
- list sederhana

Namun SharedPreferences kurang sesuai untuk menyimpan daftar catatan
yang membutuhkan query, filtering, sorting, dan relasi.

### Hive

Hive merupakan local database yang relatif mudah digunakan dan dapat
menyimpan object secara lokal.

Hive memiliki boilerplate yang relatif kecil, tetapi kebutuhan query
relasional dan struktur database kompleks lebih terbatas dibandingkan
SQLite.

### sqflite / SQLite

SQLite merupakan database relasional yang cocok untuk data terstruktur.

Keunggulannya adalah:

- mendukung SQL
- mendukung query
- mendukung relasi
- mendukung transaksi
- cocok untuk jumlah data besar
- cocok untuk kebutuhan offline-first

Kekurangannya adalah developer perlu menangani SQL dan mapping data
secara manual.

### Drift

Drift merupakan database abstraction layer untuk SQLite.

Drift memberikan:

- type-safe queries
- reactive queries
- stream
- struktur database yang lebih terorganisasi

Namun setup dan boilerplate lebih besar dibandingkan sqflite untuk
aplikasi sederhana.

## Rekomendasi Awal

Gunakan:

- SharedPreferences untuk preferensi aplikasi.
- SQLite atau Drift untuk data catatan.

Untuk aplikasi sederhana, kombinasi SharedPreferences + sqflite dapat
memberikan implementasi yang relatif sederhana namun tetap mendukung
data terstruktur dan offline-first.