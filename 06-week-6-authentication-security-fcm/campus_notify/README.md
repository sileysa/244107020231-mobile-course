# Laporan Praktikum 06 — Authentication, Security & FCM

| Keterangan | Data |
|---|---|
| Nama | Sileysa Faedatul Nuraini|
| NIM | 244107020231 |
| Mata Kuliah | Pemrograman Mobile |
| Pertemuan | Minggu 6 |

---

# Tujuan

Setelah menyelesaikan codelab ini, mahasiswa mampu:

1. Menjelaskan alur autentikasi (Firebase Auth / JWT / OAuth / Google Login) dan perbedaan ID token vs access token vs refresh token;
2. Menyimpan token secara aman dengan secure storage serta menerapkan token refresh otomatis;
3. Menjelaskan arsitektur FCM: app server, Firebase, dan perangkat;
4. Meminta notification permission dan mengelola token lifecycle (getToken, onTokenRefresh);
5. Membedakan notification payload vs data payload serta perilakunya pada state foreground, background, dan terminated;
6. Menangani klik notifikasi (deep link dengan GoRouter) dan topic messaging;
7. Menerapkan prinsip keamanan dasar aplikasi mobile (tidak menyimpan secret di kode, tidak log token).

# Praktikum 1

| Token Refresh | Login | Login Username |
|---|---|---|
| ![debug](screenshots/debug_fcm.png) | ![login](screenshots/login.png) | ![username](screenshots/username.png) |

# Praktikum 2

| Foreground | Background | Terminated |
|---|---|---|
| ![banner](screenshots/banner_prak2.png) | ![notifikasi](screenshots/notif_prak2.png) | ![prak2](screenshots/prak2.png)|

# Praktikum 3

| Foreground | Background | 
|---|---|
| ![banner](screenshots/banner_prak3.png) | ![notifikasi](screenshots/notif_prak3.png) |

| Terminated | Tombol di Terminated |
|---|---|
| ![prak3](screenshots/prak3_1.png) | ![prak3](screenshots/prak3_2.png) |

# AI Challenge

Dokumentasi AI Challenge:

[Dokumentasi AI](docs/)

# Refactoring, testing, dan error umum

| Analyze | Test |
|---|---|
| ![analyze](screenshots/analyze.png) | ![test](screenshots/test.png) |

# Refleksi

### 1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?

Refresh token sebaiknya tidak disimpan di SharedPreferences karena SharedPreferences ditujukan untuk penyimpanan data sederhana dan bukan sebagai tempat penyimpanan credential yang sensitif. Refresh token memiliki umur lebih panjang dibandingkan access token dan dapat digunakan untuk mendapatkan access token baru.

Pada project Campus Notify, refresh token disimpan menggunakan `flutter_secure_storage` agar penyimpanannya lebih terlindungi. Jika refresh token bocor, orang lain berpotensi menggunakannya untuk mendapatkan access token baru dan mengakses akun pengguna tanpa harus mengetahui password.

### 2. Apa yang rusak bila `onTokenRefresh` diabaikan selama satu semester perkuliahan?

Token FCM tidak selalu bersifat permanen. Token dapat berubah, misalnya setelah aplikasi di-install ulang, data aplikasi dihapus, atau terjadi perubahan tertentu pada perangkat.

Jika `onTokenRefresh` diabaikan, backend dapat menyimpan token lama. Akibatnya, ketika kampus mengirim notifikasi, perangkat pengguna mungkin tidak lagi menerima notifikasi tersebut.

Pada project Campus Notify, `onTokenRefresh` digunakan untuk mengirim token terbaru ke backend melalui mekanisme `POST /devices`. Dengan demikian, backend dapat memperbarui token perangkat pengguna.

### 3. Kapan memakai topik dan kapan memakai token perangkat?

**Topic** digunakan ketika pesan ditujukan kepada banyak pengguna dengan kategori yang sama atau bersifat broadcast.

Pada project ini digunakan topic:

`pengumuman-kampus`

Sedangkan **token perangkat** digunakan untuk pesan yang bersifat personal dan hanya ditujukan kepada perangkat pengguna tertentu.

Pesan personal tidak sebaiknya menggunakan topic karena pengguna lain yang berlangganan topic tersebut juga dapat menerima pesan.

### 4. Bagian mana dari draf AI yang ditolak atau diperbaiki, dan mengapa?

Draf AI tidak langsung digunakan tanpa pengujian. Beberapa bagian diperiksa dan diperbaiki secara manual berdasarkan hasil `flutter analyze`, `flutter test`, dan pengujian langsung pada emulator.

Perbaikan yang dilakukan antara lain:

1. **Foreground notification**

   FCM tidak otomatis menampilkan banner ketika aplikasi sedang terbuka. Oleh karena itu, `onMessage` diperbaiki agar menampilkan local notification menggunakan `flutter_local_notifications`.

2. **Klik notification**

   Handler `onMessageOpenedApp` digunakan untuk kondisi background, sedangkan `getInitialMessage()` digunakan untuk kondisi terminated. Keduanya meneruskan `data.route` ke GoRouter.

3. **Local notification click**

   Payload route disimpan melalui `pendingDeepLink` jika router belum siap. Setelah router siap, route tersebut diteruskan untuk melakukan navigasi.

4. **Background handler**

   Background handler dipastikan berupa fungsi top-level dengan `@pragma('vm:entry-point')`. Handler tidak menggunakan `BuildContext`, Riverpod, atau GoRouter karena berjalan pada isolate terpisah.

5. **Token lifecycle**

   `getToken()` digunakan untuk memperoleh token awal dan `onTokenRefresh` digunakan untuk memantau perubahan token. Token terbaru kemudian dikirim ke backend.

6. **Pengujian**

   Draf AI tidak dianggap benar hanya berdasarkan kode. Perilaku FCM dibuktikan melalui pengujian langsung pada emulator untuk kondisi foreground, background, dan terminated.

Kesimpulannya, AI digunakan sebagai alat untuk membantu membuat draf awal, tetapi keputusan akhir tetap dilakukan berdasarkan hasil analisis kode dan pengujian aplikasi.

## Praktikum Minggu 7 — Audit Layer Project Lama

Project yang diaudit adalah `campus_notify` dari Minggu 6. Audit ini hanya memetakan kode yang sudah ada; belum ada pemindahan atau penambahan fitur.

### Pemetaan file ke layer

| File | Layer saat ini | Masalah / catatan |
|---|---|---|
| `lib/main.dart` | Composition root / bootstrap | Menginisialisasi Firebase, notifikasi, dan GoRouter sekaligus. Wiring aplikasi sebaiknya dipisahkan dari konfigurasi rute agar entry point lebih tipis. |
| `lib/routes.dart` | Presentation / navigasi | Berisi konstanta dan pembentuk URL; tidak ada masalah layer yang berarti. Konfigurasi GoRouter sendiri masih dibuat di `main.dart`. |
| `lib/pages/login_page.dart` | Presentation | Mengelola input dan menampilkan error dari provider. Tidak mengakses jaringan atau storage langsung. |
| `lib/pages/home_page.dart` | Presentation | Mengirim aksi logout ke provider dan navigasi ke rute pengumuman. Tidak mengakses jaringan atau melakukan parsing/formatting data. |
| `lib/pages/announcement_page.dart` | Presentation | Menampilkan konten statis. Belum ada sumber data atau logika pengumuman yang perlu dipindahkan. |
| `lib/pages/debug_fcm_page.dart` | Presentation | Memanggil service FCM/notifikasi secara langsung melalui `push_service.dart`; koordinasi izin dan token sebaiknya lewat provider/use case. Token FCM juga ditampilkan di UI debug. |
| `lib/providers/auth_provider.dart` | Presentation (state) + DI | Provider membuat `AuthRepository()` konkret dan `TokenStore()` langsung. Repository belum berupa kontrak domain sehingga dependency belum dapat diganti lewat abstraksi. |
| `lib/data/auth_repository.dart` | Data (kontrak dan implementasi tercampur) | Kelas repository sekaligus mengimplementasikan perilaku login/refresh dan validasi kredensial demo. Pisahkan interface domain dari implementasi data; validasi bisnis jangan tertanam dalam adapter data. |
| `lib/data/token_store.dart` | Data / infrastructure | Implementasi storage token bergantung langsung pada `FlutterSecureStorage`; pertahankan akses platform ini di data source, bukan di widget/provider state. |
| `lib/data/api_client.dart` | Data / infrastructure | Mengonfigurasi Dio dan interceptor refresh. File ini belum ditemukan pemanggilnya di `lib`; header otorisasi pada request dan retry juga masih placeholder. |
| `lib/data/api_errors.dart` | Data / infrastructure | Mengubah `DioException` menjadi teks UI langsung. Lebih baik petakan error teknis menjadi failure domain, lalu biarkan presentation menentukan pesan. |
| `lib/messaging/push_service.dart` | Infrastructure / integrasi Firebase | Menggabungkan FCM, local notification, parsing route dari payload, dan callback navigasi. Presentation memanggilnya langsung dari halaman debug; batas antara adapter notifikasi dan navigasi masih tercampur. |

### Hasil pencarian tiga pelanggaran klasik

Pencarian dilakukan pada `lib/pages` dan `lib/providers` sesuai kategori tugas. Folder `lib/widgets` belum ada.

| Kategori | Hasil | Temuan |
|---|---:|---|
| Akses jaringan/database/storage langsung di widget (`Dio`, `http`, database, secure storage) | 0 | Tidak ada kecocokan langsung pada halaman. `DebugFcmPage` tetap mengoordinasikan service FCM secara tidak langsung; pola grep tersebut tidak mendeteksi pemanggilan service. |
| Parsing/formatting data dalam widget (`DateFormat`, `jsonDecode`, `toIso8601String`) | 0 | Tidak ada kecocokan pada halaman. |
| Instansiasi repository/client (`Repository(`, `Dio(BaseOptions`) | 1 | `lib/providers/auth_provider.dart` membuat `AuthRepository()` pada provider. Ini berfungsi sebagai registrasi DI sederhana, tetapi masih terikat ke kelas konkret; pindahkan wiring ke composition/DI dan gunakan kontrak domain. Tidak ada instansiasi Dio di presentation. |

`TokenStore()` juga dibuat langsung oleh provider, tetapi tidak cocok dengan pola grep `Repository(`. Catatan ini tetap perlu ditangani saat pemisahan DI.

### Struktur target untuk fitur yang sudah ada

Fitur autentikasi yang sudah berjalan menjadi target pemisahan; skeleton ini bukan permintaan untuk menambah fitur:

```text
lib/
├── core/
│   ├── failures.dart
│   └── providers.dart                 # registrasi dependency lintas fitur
├── features/
│   └── auth/
│       ├── domain/
│       │   ├── entities/auth_session.dart
│       │   ├── repositories/auth_repository.dart  # interface
│       │   └── usecases/
│       │       ├── login.dart
│       │       └── refresh_session.dart
│       ├── data/
│       │   ├── datasources/token_store.dart
│       │   └── repositories/auth_repository_impl.dart
│       └── presentation/
│           ├── providers/auth_provider.dart
│           └── pages/login_page.dart
├── pages/
│   ├── home_page.dart
│   ├── announcement_page.dart
│   └── debug_fcm_page.dart
└── routes.dart
```

`announcement_page.dart` tetap menjadi halaman presentation karena kontennya masih statis. File atau lapisan data baru untuk pengumuman tidak dibuat pada audit ini.
