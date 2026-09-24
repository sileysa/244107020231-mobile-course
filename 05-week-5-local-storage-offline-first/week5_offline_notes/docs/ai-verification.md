# AI Verification

## 1. Apakah AI menempatkan catatan di SharedPreferences?

Tidak.

Catatan tidak menggunakan SharedPreferences karena catatan
merupakan koleksi data yang membutuhkan query dan dapat memiliki
banyak record.

## 2. Apakah mendukung antrean sync?

Ya.

Tabel notes memiliki:

- dirty
- updated_at

Atribut dirty digunakan untuk menandai data yang belum tersinkronisasi.

## 3. Apakah klaim real-time menggunakan stream?

Untuk implementasi ini tidak menggunakan stream.

Aplikasi menggunakan Riverpod untuk state management dan SQLite
sebagai local storage.

## 4. Apakah boilerplate masuk akal?

Setelah mencoba instalasi dan implementasi, SQLite membutuhkan
lebih banyak kode dibanding SharedPreferences, tetapi sesuai
dengan kebutuhan data catatan.

## 5. Keputusan akhir

SharedPreferences digunakan untuk preferensi sederhana seperti
dark mode.

SQLite digunakan untuk menyimpan catatan karena mendukung data
berbentuk tabel, query, dirty flag, dan updated_at.