# AI Log - Minggu 9
## 1. Prompt

Peran: senior Flutter dev

Konteks: Flutter app catatan offline, feature-first, arsitektur
presentation -> domain <- data, Riverpod, SQLite (sqflite) + Dio, go_router.

Dependencies (pubspec.yaml):
dio: ^5.11.1
flutter_riverpod: ^3.4.3
go_router: ^18.0.1
path: ^1.9.1
sqflite: ^2.4.4

Struktur fitur notes:
lib/features/notes/
  data/ (datasources/notes_database.dart, models/note_model.dart,
         repositories/note_repository_impl.dart)
  domain/ (entities/note.dart, repositories/note_repository.dart,
           usecases/add_note.dart, delete_note.dart,
           get_dirty_note_count.dart, get_notes.dart, sync_notes.dart)
  presentation/ (pages/notes_page.dart, note_detail_page.dart,
                 providers/notes_providers.dart, widgets/note_tile.dart)

Entity (domain/entities/note.dart):
class Note {
  const Note({this.id, required this.title, this.body = '',
    required this.updatedAt, this.dirty = false});
  final int? id; final String title; final String body;
  final DateTime updatedAt; final bool dirty;
}

Kontrak repository (domain/repositories/note_repository.dart):
abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();
  Future<({Note? note, Failure? failure})> addNote({required String title, String body = ''});
  Future<Failure?> deleteNote(int id);
  Future<({int count, Failure? failure})> countDirty();
  Future<Failure?> markAllSynced();
}

Contoh gaya use case (get_notes.dart):
class GetNotes {
  const GetNotes(this._repository);
  final NoteRepository _repository;
  Future<({List<Note> notes, Failure? failure})> call() => _repository.fetchNotes();
}


```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../data/datasources/notes_database.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_dirty_note_count.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';
import '../../data/repositories/note_repository_impl.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

final deleteNoteProvider = Provider<DeleteNote>((ref) {
  return DeleteNote(ref.watch(noteRepositoryProvider));
});

final getDirtyNoteCountProvider = Provider<GetDirtyNoteCount>((ref) {
  return GetDirtyNoteCount(ref.watch(noteRepositoryProvider));
});

final syncNotesProvider = Provider<SyncNotes>((ref) {
  return SyncNotes(ref.watch(noteRepositoryProvider));
});

final notesProvider = FutureProvider<({List<Note> notes, Failure? failure})>((
  ref,
) {
  return ref.watch(getNotesProvider).call();
});

final dirtyCountProvider = FutureProvider<({int count, Failure? failure})>(
  (ref) => ref.watch(getDirtyNoteCountProvider).call(),
);

```


```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  bool _isSyncing = false;

  Future<void> _refresh() async {
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
    await ref.read(notesProvider.future);
    await ref.read(dirtyCountProvider.future);
  }

  Future<void> _addNote() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddNoteDialog(
        onSubmit: (title, body) async {
          final result = await ref
              .read(addNoteProvider)
              .call(title: title, body: body);
          final failure = result.failure;
          if (failure is ValidationFailure) return failure.message;
          if (failure != null && mounted) {
            _showMessage('Gagal menyimpan catatan: ${failure.message}');
          }
          return null;
        },
      ),
    );

    if (added != true || !mounted) return;
    await _refresh();
  }

  Future<void> _deleteNote(Note note) async {
    final id = note.id;
    if (id == null) return;

    final failure = await ref.read(deleteNoteProvider).call(id);
    if (!mounted) return;

    if (failure != null) {
      _showMessage('Gagal menghapus catatan: ${failure.message}');
      return;
    }

    await _refresh();
  }

  Future<void> _syncNotes() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    final result = await ref.read(syncNotesProvider).call();
    await _refresh();
    if (!mounted) return;

    if (result.failure != null) {
      _showMessage('Sinkronisasi gagal: ${result.failure!.message}');
    } else {
      _showMessage('Sinkronisasi berhasil');
    }

    setState(() {
      _isSyncing = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final dirtyCount = dirtyAsync.when(
      data: (result) => result.failure == null ? result.count : null,
      error: (error, _) => null,
      loading: () => null,
    );
    final dirtyError = dirtyAsync.when(
      data: (result) => result.failure?.message,
      error: (_, _) => 'Status sinkronisasi gagal dimuat.',
      loading: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _SyncStatus(
            dirtyCount: dirtyCount,
            error: dirtyError,
            isSyncing: _isSyncing,
            onSync: dirtyCount == null || dirtyCount == 0 ? null : _syncNotes,
          ),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _LoadError(
                message: 'Catatan gagal dimuat. Silakan coba lagi.',
                onRetry: _refresh,
              ),
              data: (result) {
                if (result.failure != null) {
                  return _LoadError(
                    message: 'Gagal memuat catatan: ${result.failure!.message}',
                    onRetry: _refresh,
                  );
                }

                final notes = result.notes;
                if (notes.isEmpty) {
                  return const Center(child: Text('Belum ada catatan'));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NoteTile(
                          note: note,
                          onTap: () {
                            if (note.id != null) {
                              context.push('/note/${note.id}');
                            }
                          },
                          onDelete: () => _deleteNote(note),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({
    required this.dirtyCount,
    required this.error,
    required this.isSyncing,
    required this.onSync,
  });

  final int? dirtyCount;
  final String? error;
  final bool isSyncing;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final hasDirtyNotes = dirtyCount != null && dirtyCount! > 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ListTile(
        leading: Icon(
          error != null
              ? Icons.error_outline
              : hasDirtyNotes
              ? Icons.sync_problem
              : Icons.cloud_done_outlined,
        ),
        title: Text(
          error != null
              ? 'Status sinkronisasi tidak tersedia'
              : dirtyCount == null
              ? 'Memuat status sinkronisasi...'
              : hasDirtyNotes
              ? '$dirtyCount catatan belum tersinkron'
              : 'Semua catatan sudah tersinkron',
        ),
        subtitle: Text(
          isSyncing
              ? 'Sedang melakukan sinkronisasi...'
              : error ??
                    (hasDirtyNotes
                        ? 'Perubahan tersimpan secara lokal'
                        : 'Data lokal sudah tersinkron'),
        ),
        trailing: isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(onPressed: onSync, child: const Text('Sync')),
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog({required this.onSubmit});

  /// Mengembalikan pesan error untuk kolom judul, atau null jika berhasil.
  final Future<String?> Function(String title, String body) onSubmit;

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _titleError;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final error = await widget.onSubmit(
      _titleController.text,
      _bodyController.text.trim(),
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _titleError = error;
        _isSaving = false;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: InputDecoration(
                labelText: 'Judul',
                hintText: 'Contoh: JS PeMob W5',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Isi',
                hintText: 'Tulis isi catatan...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

```

Tugas: tambah pencarian judul notes (kolom search di NotesPage) +
empty state saat tidak ada hasil. Empty state hasil pencarian harus
berbeda dari empty state "Belum ada catatan".

Batas:
- Jangan ubah arsitektur dan jangan sentuh folder data/.
- Jangan panggil SQLite/repository langsung dari widget.
- Logika filter harus di use case domain baru (search_notes.dart),
  Dart murni: tanpa import Flutter, Dio, atau sqflite.
- Jangan mengubah file selain notes_providers.dart dan notes_page.dart
  (selain file baru).
- Maks 80 baris kode baru. Sebutkan nama tiap file yang dibuat/diubah.
- Gunakan hanya API yang valid untuk versi package di atas.

Output: kode lengkap per file + 3 test case untuk use case
(cocok, huruf besar/kecil, tak cocok) + cara uji manual.

## 2. Output awal AI (perbaikan tabel di awal bagian ini)

| File | Status |
|---|---|
| `domain/usecases/search_notes.dart` | baru |
| `presentation/providers/notes_providers.dart` | diubah (2 tambahan) |
| `presentation/pages/notes_page.dart` | diubah (5 titik) |
| `test/search_notes_test.dart` | baru |

> Catatan: kode di bagian ini adalah output mentah AI, termasuk `"$_query"` di pesan empty state yang kemudian terbukti bermasalah (lihat bagian 5).

---

## 3. Verifikasi (temuan + bukti)

### 3.1 Ringkasan 6 langkah verifikasi

| # | Langkah | Bukti | Hasil |
|---|---|---|---|
| 1 | Baca tiap baris, tandai yang belum dipahami | sudah ditandai yang belum paham | Lolos |
| 2 | Cek import: `domain/` bebas Flutter/Dio/SQLite | `findstr` di `domain\` kosong; kontrol di `presentation\` banyak hasil | Lolos |
| 3 | Cek API: semua method benar ada | `flutter analyze` = No issues found (sebelum dan sesudah perbaikan) | Tidak ada method fiktif atau API kadaluarsa |
| 4 | `flutter analyze` nol warning | No issues found | Lolos |
| 5 | Test sukses dan gagal untuk search | 5 test use case + 4 widget test (lihat 3.4) | Lolos |
| 6 | Uji manual: query kosong, cocok, tak cocok | Screenshot di folder `screenshots/` | Lolos |

### 3.2 Batas arsitektur

- Perintah: `findstr /S /N /I "flutter dio sqflite" lib\features\notes\domain\*.dart` -> output kosong.
- Kontrol: perintah yang sama di `lib\features\notes\presentation\*.dart` -> banyak hasil (import Flutter dan Riverpod), jadi perintah valid dan hasil kosong di `domain/` benar-benar bukti.
- `git diff --stat`: hanya `notes_page.dart` dan `notes_providers.dart` yang berubah; folder `data/` tidak tersentuh, sesuai batas prompt.
- Ukuran kode baru: 12 baris (`search_notes.dart`) + sekitar 46 baris tambahan di dua file presentation, di bawah batas 80 baris.

### 3.3 Halusinasi API

Tidak ditemukan method fiktif. Riverpod 3 sempat diwaspadai karena API-nya berbeda dari versi 2, tetapi `flutter analyze` bersih, jadi semua API yang dipakai valid untuk versi di `pubspec.yaml`. Hasil negatif ini dicatat apa adanya.

### 3.4 Perkembangan jumlah test

| Tahap | Total test | Keterangan |
|---|---|---|
| Awal (3 test use case) | 25 hijau | Baseline project |
| + 2 widget test empty state | 27 hijau (setelah perbaikan trim) | Sebelum perbaikan: 1 merah, 1 hijau |
| + 2 test probe use case + 2 widget test (query cocok, tombol clear) | 31 hijau | Setelah refactor widget juga tetap 31 |

### 3.5 Temuan format

- `dart format --output=none --set-exit-if-changed lib test` -> `ERRORLEVEL 1`, 4 dari 44 file berubah (semuanya file fitur search: `search_notes.dart`, `notes_page.dart`, dan dua file test). 40 file lama sudah rapi.
- Perbaikan: `dart format` pada 4 file itu.
- Bukti setelahnya: `ERRORLEVEL 0`.
- Catatan: prediksi awal hanya menyebut `notes_page.dart`, ternyata tiga file lain (termasuk test yang ditulis bersama AI) juga tidak lolos formatter.

---

## 4. Review AI dan tabel usulan vs keputusan

### 4.1 Prompt review

```
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod 3, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
[search_notes.dart + git diff presentation]
```

Review dilakukan dua kali: pertama dengan diff yang terpotong (hanya hunk state dan dispose), lalu diulang dengan diff lengkap.

### 4.2 Temuan AI (ringkas)

Review 1 (diff terpotong):
1. Query kosong mengembalikan instance list yang sama dengan input (saran).
2. Filter dijalankan di `build()` pada setiap rebuild (saran).
3. Use case belum diuji di batas: query spasi saja, daftar kosong (saran).

Review 2 (diff lengkap):
1. Baris pesan empty state kemungkinan melebihi 80 kolom sehingga `dart format --set-exit-if-changed` gagal (blocker untuk checklist akhir).
2. `_query` dan `_searchController.text` menyimpan hal yang sama, dua sumber kebenaran (saran).
3. Widget test belum mencakup jalur utama: daftar menyusut dan tombol clear (saran).

### 4.3 Tabel usulan vs keputusan

| Temuan AI | Level | Bukti | Keputusan | Alasan teknis |
|---|---|---|---|---|
| Format baris melebihi batas | blocker (checklist) | `ERRORLEVEL 1`, 4 file berubah; `ERRORLEVEL 0` setelah `dart format` | **Terima** | Verifikasi akhir jobsheet memakai `dart format --set-exit-if-changed`, jadi kode yang tidak terformat membuat pemeriksaan gagal. Perbaikannya kosmetik dan tidak mengubah perilaku. Karena 40 file lain sudah rapi, hanya file fitur ini yang berubah dan diff tidak berisik. |
| Widget test belum cover jalur utama | saran | 2 widget test baru (query cocok, tombol clear), total test 27 -> 31 hijau | **Terima** | Bug `trim` lolos dari test use case karena letaknya di UI (pesan memakai `_query` mentah). Artinya inti fitur harus diuji di level widget juga, bukan hanya di use case. |
| Use case belum diuji di batas | saran | 2 test probe (query spasi saja, judul huruf besar) hijau | **Terima** | `trim()` dan `toLowerCase()` adalah sumber bug yang sudah ditemukan. Mengunci perilakunya di level use case murah (dua test kecil) dan mencegah regresi tanpa terdeteksi. |
| `_query` dan controller dobel | saran | Tidak ada bug yang bisa direproduksi | **Tolak** | `_query` dibutuhkan `build()` untuk dua hal: menampilkan ikon clear dan menyusun pesan empty state. `controller.text` sendiri tidak memicu rebuild, jadi `setState` tetap diperlukan. Mengganti dengan `ListenableBuilder` menambah kompleksitas tanpa mengubah perilaku yang bisa diamati. Keduanya selalu disinkronkan di satu tempat (`onChanged` dan `onClear`). |
| Filter di `build()` dihitung ulang tiap rebuild | saran | Tidak ada pengukuran yang menunjukkan masalah | **Tolak** | Filter hanya O(n) pada daftar catatan lokal yang kecil. Memindahkannya ke provider turunan menambah state dan aturan invalidasi (harus ikut di-invalidate saat catatan berubah), padahal belum ada bukti masalah performa. Ini optimasi prematur; ditinjau ulang jika jumlah catatan mencapai ribuan. |

---

## 5. Debug dan refactor

### 5.1 Bug terbukti (bukti wajib)

- Bug: pesan empty state memuat query mentah (dengan spasi) padahal filter memakai query yang sudah di-`trim()`.
- Reproduksi: ketik `  xyz  ` -> pesan menampilkan spasi ikut.
- Test merah: widget test "spasi di sekitar query tidak muncul di pesan" (ekspektasi `"xyz"`, ditemukan 0 widget). Test `xyz` tanpa spasi hijau, jadi finder dan teks pesan benar; kegagalan murni karena spasi.
- Akar masalah: normalisasi query terjadi di dua tempat yang tidak konsisten. `trim()` hanya ada di use case, sedangkan UI memakai `_query` mentah.
- Perbaikan (1 baris, `notes_page.dart`): `"$_query"` menjadi `"${_query.trim()}"`.
- Bukti: test merah menjadi hijau, `flutter analyze` bersih.

### 5.2 Refactor ke widget kecil

- Kolom search diekstrak dari `build()` menjadi `_SearchField` (StatelessWidget privat).
- Panjang blok kolom search di `build()`: sekitar 22 baris menjadi 8 baris.
- Panjang `build()` `_NotesPageState`: [ISI SENDIRI: sebelum] baris menjadi [ISI SENDIRI: sesudah] baris.
- Bukti perilaku tidak berubah: `flutter test` tetap 31 hijau, `flutter analyze` bersih.

### 5.3 Kejadian refactor yang tertukar

Refactor pertama menghasilkan 8 error `flutter analyze` (`Undefined name '_searchController'`, `'_query'`, dan `setState` tidak ada di `_SearchField`). Penyebab: instruksi pengganti blok `Padding(... TextField ...)` ambigu karena blok serupa ada dua (di `build()` halaman dan di dalam `_SearchField`), sehingga pemanggilan `_SearchField(...)` terpasang di dalam class `_SearchField` sendiri dan blok lama tetap di `build()` halaman. Diperbaiki dengan menukar keduanya kembali. Pelajaran: kerjakan satu perubahan per langkah dan jalankan `flutter analyze` setelah tiap perubahan, termasuk refactor kecil, karena analyzer menangkap kesalahan ini sebelum app dijalankan.

---

## 6. Bukti analyze + test

Perintah terakhir yang dijalankan di `07-week-7-clean-architecture`:

```
dart format --output=none --set-exit-if-changed lib test   -> Formatted 44 files (0 changed), ERRORLEVEL 0
flutter analyze                                            -> No issues found!
flutter test                                               -> +31: All tests passed!
```

Screenshot uji manual (folder `screenshots/`):

- `01-search-cocok.png`: query `belanja`, daftar menyusut.
- `02-search-kosong.png`: query `xyz`, pesan "Tidak ada catatan dengan judul".
- `03-belum-ada-catatan.png`: semua catatan dihapus, pesan "Belum ada catatan".