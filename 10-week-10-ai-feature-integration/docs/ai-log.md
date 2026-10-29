# AI log — integrasi chat streaming Gemini

## Konteks

- Project: kelanjutan Offline Notes dan Offline Posts Minggu 9.
- Stack: Flutter, Riverpod, Dio, clean architecture, dan `flutter_secure_storage`.
- Fitur: chat berbahasa Indonesia dengan jawaban streaming Gemini.
- Batas: tidak menyimpan chat/key di source, membatasi ukuran konteks, menolak pola
  umum data pribadi, menangani error, dan menyediakan fallback lokal.
- API key hanya digunakan melalui secure storage saat uji live di perangkat; key
  tidak dibaca, ditampilkan, atau dicatat. Prompt uji tidak memuat data pribadi.

## Prompt sistem

```text
Kamu adalah asisten kampus yang ramah. Jawab dalam Bahasa Indonesia dengan jelas
dan ringkas. Jangan meminta atau mengungkap data pribadi.
```

## Prompt pengguna uji live

```text
Halo
```

## Output awal

Output Gemini yang tampil pada pengujian di perangkat CPH2387:

```text
Halo! Ada yang bisa saya bantu terkait informasi kampus hari ini?
```

Screenshot hasil live tersimpan di `../screenshots/uji-chat-live.png`. Tidak ada
credential yang disimpan di log ini.

## Keputusan implementasi dan verifikasi

| Usulan/risiko | Keputusan | Alasan |
|---|---|---|
| Mengirim API key sebagai query parameter URL | Ditolak; gunakan header `x-goog-api-key` | Mengurangi risiko key muncul pada URL/log jaringan. |
| Menanam API key dalam source code | Ditolak; input melalui dialog dan simpan di secure storage | Tidak membocorkan credential ke repository. Key client tetap berisiko diekstrak; backend proxy disarankan untuk produksi. |
| Meminta respons sekaligus | Diganti SSE `streamGenerateContent` | Potongan jawaban dapat ditampilkan sebelum respons selesai. |
| Mengirim seluruh percakapan tanpa batas | Batasi ke 10 pesan terakhir dan 1.200 karakter per input | Mengendalikan ukuran request/biaya; 20 request per sesi juga dibatasi di aplikasi. Batas server tetap dibutuhkan. |
| Mengirim alamat/NIK/nomor/email | Blokir pola umum secara lokal dan tampilkan peringatan | Filter pola bukan deteksi PII sempurna; pengguna tetap harus menghapus data pribadi. |
| Menyimpan riwayat | Tidak disimpan ke disk | Percakapan hanya berada di memori selama sesi. Isi request tetap dikirim ke provider AI. |
| API error | Pesan error, retry, dan arahan ke catatan lokal | Aplikasi tetap dapat dipakai untuk informasi yang sudah tersimpan lokal. |

## Hasil verifikasi

Unit test menggunakan fake repository sehingga tidak memerlukan internet atau
credential. Pengujian tambahan live pada perangkat CPH2387 berhasil menerima jawaban
stream dari Gemini. `flutter analyze`, formatter, dan seluruh 24 `flutter test`
dijalankan dari terminal folder project. Tidak ada API key yang dicatat atau
ditampilkan dalam log/screenshot.
