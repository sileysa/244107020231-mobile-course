# AI Challenge: Clean Architecture untuk Notes

## Prompt

> Project Flutter saya: `week7_clean_architecture` (SQLite notes, dirty flag/sync, dan posts cache).
> Kondisi kini: folder `lib/{data,pages,widgets}`, entity notes mencampur mapping SQLite,
> repository menggabungkan kontrak dan implementasi, dan halaman mengakses repository langsung.
> Usulkan struktur feature-first Clean Architecture untuk notes dan posts. Petakan file lama ke tujuan
> barunya, tandai over-engineering untuk CRUD sederhana, tunjukkan DI dengan Riverpod tanpa
> package DI tambahan, dan jelaskan trade-off setiap keputusan. Jangan menambah fitur bisnis baru.

## Draf awal AI

- Letakkan entity dan repository interface notes di `features/notes/domain`, implementasi
  SQLite serta mapping `NoteModel` di `features/notes/data`, dan provider/notifier serta UI
  di `features/notes/presentation`.
- Inject fungsi pembuka database ke `NoteRepositoryImpl` dari provider supaya implementasi
  dapat diganti fake tanpa memulai SQLite di test.
- Gunakan `GetNotes` sebagai batas operasi baca yang mudah diuji. CRUD satu-baris lainnya
  dapat dipanggil oleh notifier melalui interface repository; jangan membuat use case untuk
  setiap getter atau operasi yang hanya meneruskan argumen.
- Pertahankan sinkronisasi sebagai use case karena menggabungkan pembacaan antrean dirty,
  jeda simulasi sync, dan pembaruan status tersinkron.
- Ekstrak pemformatan tanggal dan parsing parameter rute ke fungsi murni di `core`.
- Untuk posts, pertahankan cache-first/offline behavior dan batasi interface repository pada
  kebutuhan fitur API + cache yang benar-benar dipakai.

## Usulan dibanding keputusan

| Area | Usulan AI | Keputusan implementasi | Alasan |
|---|---|---|---|
| Entity | Entity domain bebas framework dan mapping | `Note` dipindah ke domain tanpa `toMap/fromMap` | SQLite adalah detail persistence dan bukan bagian model bisnis. |
| Repository | Interface di domain, implementasi SQLite di data | `NoteRepository` menjadi abstraksi domain dan `NoteRepositoryImpl` memetakan `NoteModel` | Arah dependensi memungkinkan fake menggantikan SQLite repository. |
| Hasil operasi | Sukses/gagal eksplisit, bukan exception platform di UI | Repository mengembalikan Dart record dengan `Failure?`; error database ditangkap pada batas data | Presentation menampilkan pesan `Failure` tanpa menangani exception sqflite. |
| Use case | Gunakan untuk operasi dengan aturan/orchestrasi, hindari CRUD satu-baris berlebihan | `GetNotes` dan `SyncNotes`; add/delete langsung melalui notifier ke interface | Baca dipisah untuk pengujian domain, sync mengorkestrasi beberapa operasi, CRUD sederhana tidak perlu wrapper tambahan. |
| Dependency injection | Riverpod menjadi composition point | Provider mengikat interface ke implementasi dan menginjeksikan DB opener | Tidak menambah container DI baru; database dapat dioverride saat tes. |
| Post/cache | Migrasikan bertahap dan pertahankan cache-first/offline behavior | Posts dipisah ke domain/data/presentation dengan satu implementasi repository yang mengelola API serta cache SQLite | API dan cache merupakan sumber dalam satu alur offline-first; satu kontrak fitur menjaga notifier bergantung pada abstraksi tanpa menambah fitur bisnis. |

## Arah dependensi

```text
presentation -> domain <- data

notes page / notifier -> Note, NoteRepository, GetNotes, SyncNotes
NoteRepositoryImpl -> NoteRepository, Note, NoteModel, sqflite
NoteModel -> Note

posts page / notifier -> Post, PostRepository, GetRemotePosts
PostRepositoryImpl -> PostRepository, Post, PostModel, Dio, sqflite
PostModel -> Post
```

Domain dan core tidak mengimpor Flutter, Riverpod, Dio, sqflite, atau Firebase. Provider
presentation provider menjadi satu titik wiring per fitur; ia mengimpor data implementation
untuk menyusunnya, tetapi data tidak mengimpor presentation.

## Pemeriksaan sterilitas

Pola pencarian yang dipakai pada fitur notes:

```text
Dio(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences.getInstance|jsonDecode
-> lib/features/notes/presentation, lib/pages: tidak ada hasil

import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase
-> lib/features/notes/domain, lib/core: tidak ada hasil
```

Pencarian awal ketiga (instansiasi `Repository(` di halaman/provider) memang menemukan
registrasi `NoteRepositoryImpl` di provider notes. Itu adalah constructor implementasi dalam
composition root Riverpod yang dikehendaki; halaman tidak membuat repository. Provider ini
juga merupakan satu-satunya lokasi wiring untuk notes.

## Pengujian

- `get_notes_test.dart`: sukses dan failure menggunakan `FakeNoteRepository`, tanpa database.
- `note_model_test.dart` dan `post_model_test.dart`: default field dan mapping SQLite/API/cache.
- `format_test.dart`: route ID valid/tidak valid dan formatting tanggal.
- `widget_test.dart`: UI notes menggunakan repository palsu.

Hasil final `flutter analyze` dan `flutter test` dicatat di README setelah dijalankan.
