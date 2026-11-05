# AI Review vs Keputusan Final

Dokumen ini mencatat hasil **AI Prompt Challenge** (Codelab Minggu 8, section 6)
dan **verifikasi mandiri** tiap temuan sebelum diterapkan ke kode.
Semua bukti verifikasi (grep, test, analyze) tercantum di dalam file ini.

- PR yang direview: **PR #2** (`sileysa/mobile-course`)
- Branch: `feature/notes-validation` → `develop`
- Tanggal review: 2026-11-05
- Reviewer (manusia): Mufliha Hafsyah
- AI reviewer: Deepseek

---

## 1. Prompt yang dikirim ke AI

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

Diff PR #2 ditempel di bawah prompt saat dikirim ke AI (tidak disertakan
ulang di dokumen ini untuk menghindari duplikasi; lihat PR #2 di GitHub).

---

## 2. Output awal AI (mentah, tidak diedit)

> **Catatan integritas:** penulis ikut menulis sebagian kode PR ini, sehingga
> review AI diperlakukan sebagai **hipotesis**, bukan keputusan. Setiap temuan
> diverifikasi ulang di section 4 dengan grep/test/manual.

### Temuan AI (ringkas)

| # | Temuan | Level |
|---|--------|-------|
| 1 | `ValidationFailure` bocor ke presentation via `is ValidationFailure` di `notes_page.dart` | blocker arsitektur |
| 2 | `_isSaving` bisa stuck `true` kalau `onSubmit` melempar exception | saran |
| 3 | `body` tidak di-trim di domain, sementara `title` di-trim — inkonsistensi | saran |
| 4 | Test `add_note_test.dart` tidak memverifikasi repository **tidak dipanggil** saat judul kosong | saran (test) |
| 5 | Test sebaiknya assert `message` bukan `isA<ValidationFailure>()` | saran (style test) |

### Detail usulan AI per temuan

**#1 — Blocker arsitektur: `ValidationFailure` bocor ke presentation**

Lokasi: `notes_page.dart`, blok `onSubmit`:

```dart
final failure = result.failure;
if (failure is ValidationFailure) return failure.message;
```

Alasan AI: presentation mengunci tipe konkret `ValidationFailure`. Kalau tipe
failure dipecah (mis. `TitleTooLongFailure`, `DuplicateNoteFailure`), widget
harus diubah. Lebih baik pindahkan mapping `Failure → (fieldError, snackBar)`
ke satu fungsi di presentation.

Usulan AI:

```dart
// presentation/mappers/failure_presenter.dart
class FailurePresenter {
  static ({String? fieldError, String? snackBar}) present(Failure? f) {
    return switch (f) {
      null => (fieldError: null, snackBar: null),
      ValidationFailure(:final message) => (fieldError: message, snackBar: null),
      _ => (fieldError: null, snackBar: 'Gagal menyimpan catatan: ${f.message}'),
    };
  }
}
```

**#2 — Saran: `_isSaving` bisa stuck `true` bila `onSubmit` throw**

Alasan AI: kalau `onSubmit` melempar exception (bukan mengembalikan `Failure`),
`_isSaving` tidak pernah kembali `false` → tombol Simpan mati sampai dialog
ditutup. Usul: bungkus `_submit` dengan `try/finally`.

**#3 — Saran: `body` tidak di-trim di domain**

Alasan AI: `add_note.dart` mem-`trim` `title` tapi tidak `body`; inkonsisten.
Usul: trim body di use case juga.

**#4 — Saran (test): test tidak memverifikasi repo tidak dipanggil**

Alasan AI: judul test *"menolak judul kosong tanpa memanggil repository"*
overpromise — isinya hanya assert `result.failure isA<ValidationFailure>()`
dan `result.note isNull`. Kalau `AddNote` lupa short-circuit dan tetap
memanggil `addNote`, test tetap lulus. Usul: tambah counter `addCallCount`
di `FakeNoteRepository` dan assert `== 0`.

**#5 — Saran (style test): assert pada `message` bukan `isA<ValidationFailure>()`**

Alasan AI: mengunci tipe konkret membuat test rapuh saat refactor.

---

## 3. Ringkasan keputusan

| Diterima | Ditolak | Total |
|----------|---------|-------|
| **2** (#1, #4) | **3** (#2, #3, #5) | 5 |

- Syarat jobsheet **≥ 2 temuan terbukti benar** → **terpenuhi** (#1, #4)
- Syarat jobsheet **≥ 1 temuan ditolak dengan alasan tertulis** → **terpenuhi** (#2, #3, #5)

---

## 4. Tabel verifikasi & keputusan

| # | Temuan AI | Level | Bukti verifikasi | Keputusan | Alasan |
|---|-----------|-------|------------------|-----------|--------|
| 1 | `ValidationFailure` bocor ke presentation via `is ValidationFailure` | blocker arsitektur | `findstr /s /i "ValidationFailure" lib\features\notes\presentation\*`<br>→ `notes_page.dart: if (failure is ValidationFailure) return failure.message;` | **Diterima** | Presentation mengunci tipe konkret failure. Solusi: mapping `Failure → (fieldError, snackBar)` dipindah ke satu fungsi di presentation (`failure_presenter.dart`) agar widget tree tidak perlu tahu tipe konkret. |
| 2 | `_isSaving` bisa stuck `true` bila `onSubmit` throw | saran | `findstr /s /i "throw" lib\features\notes\data\*.dart`<br>→ **(kosong)** | **Ditolak** | Data layer konsisten mengembalikan `Failure` via record `({Note? note, Failure? failure})`, tidak pernah melempar exception. Jalur "throw → `_isSaving` stuck" tidak ada. `try/finally` adalah hardening untuk skenario hipotetis, bukan bug nyata di PR ini. |
| 3 | `body` tidak di-trim di domain | saran | `add_note.dart`:<br>`return _repository.addNote(title: cleanTitle, body: body);` | **Ditolak** | Body multi-line **sengaja** membawa indentasi (mis. catatan bertingkat/kode). Trim hanya di `title` adalah keputusan desain sadar untuk mencegah baris kosong di awal/akhir field judul, tanpa merusak format body. Bukan inkonsistensi bug. |
| 4 | Test tidak memverifikasi repo tidak dipanggil saat judul kosong | saran (test) | `findstr /s /i "addCallCount" test\fakes\fake_note_repository.dart`<br>→ **(kosong)**<br><br>Isi `fake_note_repository.dart` (method `addNote`):<br>```dart<br>Future<({Note? note, Failure? failure})> addNote({...}) async {<br>  if (failure != null) return (note: null, failure: failure);<br>  return (note: Note(...), failure: null);<br>}<br>```<br>→ **tidak ada counter/increment** | **Diterima** | Judul test *"menolak judul kosong tanpa memanggil repository"* **overpromise** — isinya hanya assert `result.failure isA<ValidationFailure>()` dan `result.note isNull`. Kalau `AddNote` lupa short-circuit dan tetap memanggil `addNote`, test **tetap lulus** (fake juga menolak). Bug tidak tertangkap. Perbaikan: tambah counter `int addCallCount = 0;` di fake + assert `== 0`. |
| 5 | Test sebaiknya assert `message` bukan `isA<ValidationFailure>()` | saran (style test) | — (kualitatif) | **Ditolak** | `isA<ValidationFailure>()` adalah **kontrak eksplisit** use case. Mengunci tipe failure **memang seharusnya** memecahkan test saat tipe berubah — itu sinyal refactor, bukan regresi. Assert pada `message` string akan rapuh tiap copywriting berubah. Ini nitpick style test; fokus PR adalah validasi judul. |

---

## 5. Bukti mesin hijau

```
$ flutter analyze
Analyzing 07-week-7-clean-architecture...
No issues found! (ran in 5.5s)

$ flutter test
00:10 +22: All tests passed!
```

---

## 6. Tindak lanjut

- [ ] Temuan #1 diterapkan → PR perbaikan terpisah `fix/notes-failure-presenter`
- [x] Temuan #2 ditolak — tidak ada `throw` di data layer (grep kosong)
- [x] Temuan #3 ditolak — body multi-line sengaja membawa indentasi
- [ ] Temuan #4 diterapkan → tambah `addCallCount` di `FakeNoteRepository` + assert di test
- [x] Temuan #5 ditolak — `isA<ValidationFailure>()` adalah kontrak use case

---

## 7. Refleksi (Codelab Minggu 8, section 8)

**Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?**

> LGTM buta = approve tanpa checkout dan tanpa jalankan test. Approve
> bertanggung jawab = reviewer checkout branch, jalankan `flutter analyze`
> + `flutter test`, reproduksi minimal 1 perilaku, dan mengonfirmasi tiap
> komentar ditindaklanjuti. Risiko LGTM buta: bug lolos ke develop dan
> penulis kehilangan sinyal untuk memperbaiki.

**Kapan komentar wajib berstatus request changes, dan kapan cukup saran?**

> Request changes untuk blocker (melanggar dependency rule, bug nyata,
> test merah, `analyze` tidak bersih). Saran untuk hardening, keterbacaan,
> dan test yang belum menutup edge case tapi tidak menghambat merge.
> Di PR ini, temuan #1 layak request changes (blocker arsitektur); #4 saran
> karena test tetap lulus walau overpromise.

**Bagian mana dari review AI yang kamu tolak atau sederhanakan, dan mengapa?**

> Kami menolak temuan #2 (grep kosong: tidak ada `throw` di data layer),
> temuan #3 (trim body adalah pilihan desain untuk multi-line), dan
> temuan #5 (mengunci tipe `ValidationFailure` justru kontrak use case,
> bukan cacat). Tiga penolakan punya alasan teknis tertulis dan bukti
> grep — bukan berdasarkan "AI-nya kurang yakin".

**Satu hal konkret yang kamu perbaiki setelah review sejawat — apa dampaknya?**

> Setuju, terima kasih. Duplikasi sudah dihapus di commit a1b0c1d: dialog sekarang memanggil use case dan menampilkan failure.message di kolom judul, jadi UI tidak lagi mengetahui aturan validasinya. Dialog tetap terbuka saat error sehingga isi catatan tidak hilang. Sudah diuji manual (judul kosong dan 3 spasi), screenshot terlampir.

---