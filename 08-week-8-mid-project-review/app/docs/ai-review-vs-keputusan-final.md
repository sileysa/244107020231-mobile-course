# Usulan AI vs Keputusan Final

| # | Usulan/temuan | Verifikasi | Keputusan final | Alasan/bukti |
|---|---|---|---|---|
| 1 | **Blocker:** request dapat selesai setelah `OfflinePostsNotifier` disposed dan melanjutkan akses `ref`/state. | Alur async pada `build`, `refresh`, dan `_refreshFromApi` berlanjut setelah `await`; regression test menguji background dan manual refresh yang dihentikan saat disposal. | **Terima dan perbaiki.** | Tambahkan `ref.mounted` guard sebelum akses provider/state berikutnya. Test terkait ada di `app/test/posts_providers_test.dart`. |
| 2 | **Saran:** refresh manual membuang daftar lama selama request berjalan. | `refresh()` menetapkan `AsyncLoading`; UI menampilkan loading branch. | **Valid, ditunda.** | Ini perubahan UX tersendiri dan bukan blocker kebenaran. Mempertahankan data lama perlu keputusan UX dan test widget khusus. |
| 3 | **Saran:** belum ada test orkestrasi notifier posts. | Daftar test sebelum perubahan mencakup model posts, bukan `OfflinePostsNotifier`. | **Terima dan perbaiki.** | Dua test baru mencakup request background dan manual yang masih pending saat provider dibuang. |
| 4 | **Saran:** ekstrak alur fallback menjadi helper untuk keterbacaan. | `refresh()` memiliki beberapa cabang, tetapi tiap cabang masih pendek dan urutannya dapat dibaca. | **Tolak untuk saat ini.** | Helper tambahan belum mengurangi kompleksitas; pertimbangkan lagi bila fallback dipakai ulang atau bertambah. |
| 5 | **Saran arsitektur:** pindahkan wiring repository/database keluar dari provider posts di presentation. | Provider tersebut mengimpor implementasi data dan sqflite, tetapi domain tetap hanya menggunakan abstraksi. README aplikasi Week 7 secara eksplisit menetapkan provider Riverpod sebagai composition root per fitur. | **Tolak berdasarkan keputusan arsitektur project saat ini.** | Wiring tersebut adalah batas DI yang terdokumentasi, bukan akses database dari domain atau widget. Jika tim menghapus pengecualian composition-root ini, lokasi provider perlu ditinjau ulang. |

## Tanggung jawab teknis

Temuan AI tidak diterapkan mentah. Lifecycle issue diterima setelah dicocokkan dengan alur
async dan ditambah regression test. Usulan arsitektur ditolak berdasarkan keputusan Week 7
yang telah terdokumentasi. Saran UX dipisahkan dari blocker dan menunggu keputusan eksplisit.
