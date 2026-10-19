# AI log — pencarian judul catatan

## Konteks

- Project: kelanjutan Offline Notes Minggu 8, bukan project baru.
- Arsitektur: feature-first, Riverpod; repository untuk persistence, use case domain
  untuk aturan bisnis.
- Package: Flutter/Dart, `flutter_riverpod`, `sqflite`, Dio, dan GoRouter. Tidak ada
  secret atau credential yang diberikan ke AI.
- Batasan: cari judul saja, tanpa mengubah repository/database, dengan empty state,
  unit test, dan widget test.

## Prompt inti (5 slot)

```text
Peran: senior Flutter developer.
Konteks: aplikasi Offline Notes Minggu 8, feature-first, Riverpod, repository pattern,
SQLite. Domain tidak boleh mengimpor Flutter, Dio, atau SQLite.
Tugas: tambahkan pencarian substring pada judul catatan, tidak peka kapitalisasi,
dan tampilkan empty state jika query tidak menemukan hasil.
Batas: jangan mengubah kontrak/persistence repository; filter harus pure dan berada
di domain; pertahankan state loading/error dan aksi catatan yang sudah ada.
Output: perubahan kode minimal, unit test untuk query cocok/tidak cocok, widget test
empty state, serta perintah verifikasi.
```

## Rancangan awal AI (sebelum verifikasi)

```dart
List<Note> filterNotes(List<Note> notes, String query) {
  if (query.isEmpty) return notes;
  return notes.where((note) => note.title.contains(query)).toList();
}
```

Rancangan ini tidak menormalisasi kapitalisasi dan whitespace. Implementasi awal
tersebut berisiko gagal menemukan judul `Belanja Bulanan` untuk query `belanja`.
Saya tidak mengintegrasikannya mentah: unit test case-insensitive menjadi bukti
regresi dan implementasi final memang menormalisasi kedua sisi pencarian.

## Keputusan per file

| File | Keputusan | Alasan |
|---|---|---|
| `lib/features/notes/domain/usecases/search_notes.dart` | Terima + refactor | Filter pure, trim query, abaikan kapitalisasi, dan hanya mencocokkan title. |
| `lib/pages/notes_page.dart` | Terima + refactor | UI menyimpan query dan menampilkan empty state; akses repository/database tidak ditambahkan. |
| `test/search_notes_test.dart` | Terima | Membuktikan pencocokan case-insensitive, hasil kosong, dan query kosong. |
| `test/widget_test.dart` | Terima + refactor | Membuktikan empty state pencarian pada UI. |

## Review AI: usulan vs keputusan

| Usulan | Keputusan | Alasan teknis / bukti |
|---|---|---|
| Gunakan `String.contains` langsung pada judul | Tolak lalu refactor | Case-sensitive; test `pencarian judul mengabaikan huruf besar dan kecil` memerlukan hasil untuk query `belanja` terhadap `Belanja Bulanan`. |
| Cari juga di body agar hasil lebih luas | Tolak | Requirement codelab secara spesifik meminta pencarian judul; mencampur body mengubah kontrak pencarian dan membuat hasil tak terduga. Fixture unit test memastikan body yang cocok saja tidak menghasilkan match. |

### Bukti temuan

```text
rg -n 'contains\(query\)' lib
```

Pola exact untuk rancangan awal tidak ditemukan pada kode final. Bukti perilakunya ada
di `test/search_notes_test.dart`: judul `Belanja Bulanan` dicari memakai `belanja`
dan tetap ditemukan. Test di file yang sama juga memastikan query hanya memeriksa judul,
bukan body.

## Hasil verifikasi

Jalankan dari root project setelah perubahan final:

```text
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

Hasil aktual dari root project:

| Perintah | Hasil |
|---|---|
| `dart format --set-exit-if-changed lib test` | Lulus; 32 file diperiksa, tidak berubah |
| `flutter analyze` | Lulus; `No issues found!` |
| `flutter test` | Lulus; 14 test |

Pemeriksaan manual dilakukan pada emulator Android dengan dua catatan contoh, `Belanja
Bulanan` dan `Agenda Kuliah`. Screenshot query kosong, query `belanja` yang cocok, dan
query `zzz` yang tidak cocok disimpan di `../screenshots/`. Sudut gambar dibuat sedikit
membulat dan garis tepi emulator dipotong. Unit dan widget test juga menggunakan fixture
terkontrol untuk ketiga kondisi pencarian.
