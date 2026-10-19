# Bukti Verifikasi

Hasil di bawah mencatat perintah yang dijalankan pada salinan aplikasi di folder `app/`
setelah perubahan Week 8. Ganti status jika ada perubahan kode setelah verifikasi ini.

## Regression test posts provider

```text
flutter test test/posts_providers_test.dart
All tests passed!
```

Mencakup background refresh dan manual refresh yang tertunda ketika provider dibuang.

## Project checks

| Perintah | Hasil |
|---|---|
| `dart format --set-exit-if-changed lib test` | Lulus; 30 file diperiksa, 0 perubahan setelah pemformatan awal |
| `flutter analyze` | Lulus; `No issues found!` |
| `flutter test` | Lulus; 10 tests passed |

Pemeriksaan sterilitas yang dijalankan pada `lib/features/*/presentation` dan `lib/pages`
untuk akses langsung Dio/database/secure storage/JSON menghasilkan **0 hasil**. Pemeriksaan
`lib/core` dan domain notes/posts untuk import Flutter/Dio/sqflite/Firebase juga menghasilkan
**0 hasil**. Pencarian instansiasi repository implementation di `lib/pages` menghasilkan
**0 hasil**.

## Batasan pemeriksaan

Pemeriksaan formatter dan workflow CI dibatasi ke `lib test`, yaitu source serta test Dart
yang dipelihara. Cache/build tidak disalin ke paket aplikasi; Flutter akan menghasilkan
kembali file yang diperlukan setelah `flutter pub get` atau saat aplikasi dijalankan.

Workflow akan menjalankan formatter, analyze, dan test pada pull request. Bukti run GitHub
Actions belum tersedia karena branch belum dipush dan belum ada Pull Request.
