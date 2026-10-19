# Review Checklist — Week 8

## Hygiene branch dan commit

Repository awal hanya memiliki `main`. Untuk mengikuti jobsheet, branch `develop` dibuat
lokal dari `main`, lalu branch kerja `feature/week8-mid-project-review` dibuat dari
`develop`. Branch baru belum dipush; remote dan kolaborator tidak diubah.

Berikut simulasi penulisan ulang tiga subject dari riwayat Week 7. Usulan merangkum scope
berdasarkan file yang berubah; commit lama tidak di-rewrite karena perubahan tersebut sudah
menjadi bagian riwayat repository.

| Commit | Subject lama | Usulan konvensional | Alasan |
|---|---|---|---|
| `a3bb8f5` | `07-week-7-clean-architecture` | `refactor(week7): pisahkan notes dan posts ke feature layers` | Menyebut perubahan arsitektur yang ditambahkan pada commit tersebut. |
| `db5ff19` | `07-week-7-clean-architecture` | `docs(week7): tambahkan screenshot setelah refactor` | Menjelaskan dokumentasi dan bukti screenshot yang diperbarui. |
| `1379711` | `07-week-7-clean-architecture` | `docs(week7): perbarui laporan dan screenshot aplikasi` | Menjelaskan perubahan laporan dan screenshot pada commit terakhir. |

## Kesiapan PR

| Pemeriksaan | Hasil |
|---|---|
| Branch kerja dibuat dari `develop` | Lulus secara lokal |
| Issue yang mendeskripsikan pekerjaan | Belum tersedia |
| PR kecil dengan masalah, solusi, cara uji, screenshot | Belum dibuat |
| PR ditargetkan ke `develop` dan ditutup via merge | Belum dilakukan |
| Minimal tiga komentar review sejawat ditindaklanjuti | Menunggu review sejawat |
| Screenshot dan cara menjalankan tersedia | Ada di `app/README.md` dan README Week 8 |

Jangan menandai mid review lolos sebelum issue/PR, peer review, dan merge benar-benar
dilakukan.

Template PR untuk pekerjaan ini tersedia di
[`.github/pull_request_template.md`](../../.github/pull_request_template.md).

## Checklist mesin dan arsitektur

- [x] Domain bebas dari import Flutter, Dio, sqflite, dan Firebase.
- [x] Provider posts menghentikan pekerjaan async setelah provider dibuang.
- [x] Regression test untuk disposal pada background refresh dan manual refresh.
- [x] `flutter analyze`, formatter, dan test dijalankan; lihat
  [`verification-results.md`](verification-results.md).
- [ ] Re-review dan approval oleh pasangan.
- [ ] PR di-merge ke `develop`, lalu issue ditutup otomatis.

## Catatan review target

Target: `app/lib/features/posts/presentation/providers/posts_providers.dart`.
Temuan correctness yang ditindaklanjuti adalah pemakaian provider setelah `await` saat
notifier sudah disposed. Perubahan menambahkan pemeriksaan `ref.mounted` sebelum melanjutkan
operasi atau menulis state. Temuan dan keputusan lengkap ada di
[`ai-review-vs-keputusan-final.md`](ai-review-vs-keputusan-final.md).
