# AI Prompt Challenge

Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.

# AI Verification Checklist

| Checklist | Hasil Verifikasi | Temuan |
|---|---|---|
| State diubah secara immutable | ✅ Sesuai | Pada `TodoListNotifier`, state tidak diubah menggunakan `state.add()` atau mutasi langsung. Data dibuat menjadi list baru menggunakan spread operator `[...]`. |
| `ref.watch` digunakan di `build` dan `ref.read` pada callback | ✅ Sesuai | `ref.watch()` digunakan di dalam `build()` untuk mengamati perubahan state, sedangkan `ref.read()` digunakan pada callback seperti tambah, toggle, hapus, dan retry. |
| Ketiga state `AsyncValue` ditangani | ✅ Sesuai | `StatsPage` menangani kondisi `loading`, `error`, dan `data` menggunakan `statsAsync.when()`. |
| Provider memiliki tipe eksplisit dan tidak duplikat | ✅ Sesuai | `todoListProvider`, `filteredTodoProvider`, dan `statsProvider` memiliki deklarasi tipe yang jelas dan tidak terdapat provider duplikat. |
| Tidak menggunakan API Riverpod versi lama | ✅ Sesuai | Implementasi menggunakan `Notifier`, `AsyncNotifier`, `NotifierProvider`, `AsyncNotifierProvider`, dan `ConsumerWidget`. Tidak menggunakan `StateNotifierProvider` atau `StateProvider`. |
| `flutter analyze` | ✅ Lolos | Tidak ditemukan error maupun warning. |
| `flutter test` | ✅ Lolos | Seluruh test berhasil dijalankan. |

Halaman Produk Loading

![produk_loading](../screenshots/produk_loading.png)

Halaman Produk Success

![produk_success](../screenshots/produk_success.png)

Halaman Produk Error

![produk_error](../screenshots/produk_error.png)

| Flutter Analyze | Flutter Test |
|---|---|
| ![Analyze](../screenshots/flutter_analyze.png) | ![Test](../screenshots/flutter_test.png) |