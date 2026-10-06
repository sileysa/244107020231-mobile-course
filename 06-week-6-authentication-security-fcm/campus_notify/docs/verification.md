# AI Verification — Campus Notify

## 1. Tujuan Verifikasi

Verifikasi ini dilakukan untuk memastikan bahwa implementasi Firebase Cloud
Messaging (FCM) pada aplikasi **Campus Notify** tidak hanya dibuat berdasarkan
hasil AI, tetapi juga telah diperiksa dan diuji secara langsung.

Hal yang diverifikasi meliputi:

1. Background handler.
2. FCM token dan perubahan token.
3. Foreground notification.
4. Background notification.
5. Terminated notification.
6. Navigasi berdasarkan `data.route`.
7. Topic messaging.
8. Keamanan token dan secret.
9. Perbedaan perilaku notification pada setiap app state.

---

# 2. Background Handler

## Hasil Verifikasi: PASS

Background handler pada aplikasi dibuat sebagai fungsi **top-level**, bukan
sebagai method di dalam class.

Implementasinya menggunakan:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  debugPrint(
    'Background message received: ${message.messageId}',
  );

  debugPrint(
    'Title: ${message.notification?.title}',
  );

  debugPrint(
    'Body: ${message.notification?.body}',
  );

  debugPrint(
    'Data: ${message.data}',
  );
}
```

Handler kemudian didaftarkan menggunakan:

```dart
FirebaseMessaging.onBackgroundMessage(
  firebaseMessagingBackgroundHandler,
);
```

### Alasan teknis

Background handler dapat berjalan pada isolate terpisah sehingga tidak boleh
bergantung pada UI aplikasi.

Oleh karena itu handler tidak menggunakan:

* `BuildContext`;
* widget;
* navigasi secara langsung;
* state UI;
* Riverpod untuk mengakses UI.

Navigasi dilakukan ketika pengguna mengklik notification, bukan dari dalam
background handler.

### Kesimpulan

Background handler sudah sesuai dengan ketentuan praktikum karena berupa
fungsi top-level dan menggunakan `@pragma('vm:entry-point')`.

---

# 3. Request Notification Permission

## Hasil Verifikasi: PASS

Permission notification diminta menggunakan:

```dart
final settings =
    await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
  announcement: false,
  carPlay: false,
  criticalAlert: false,
);
```

Status permission kemudian diperiksa:

```dart
return settings.authorizationStatus ==
        AuthorizationStatus.authorized ||
    settings.authorizationStatus ==
        AuthorizationStatus.provisional;
```

Permission ini diperlukan agar aplikasi dapat menampilkan notification
kepada pengguna.

Pada perangkat Android yang digunakan, notification permission telah
diberikan dan notification berhasil diterima.

---

# 4. FCM Token

## Hasil Verifikasi: PASS

FCM token diperoleh menggunakan:

```dart
final token =
    await FirebaseMessaging.instance.getToken();
```

Token yang diperoleh kemudian dapat dikirim melalui callback:

```dart
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token =
      await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await onToken(token);
  }
}
```

Aplikasi juga memantau perubahan token:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
```

### Alasan teknis

FCM token dapat berubah sehingga aplikasi tidak boleh hanya mengambil token
satu kali ketika aplikasi pertama kali dijalankan.

`onTokenRefresh` digunakan untuk memperoleh token terbaru.

### Keamanan

Token tidak di-hardcode di dalam source code.

Token juga tidak digunakan sebagai password atau secret aplikasi.

Pada halaman debug, token hanya ditampilkan secara terbatas untuk membantu
proses pengujian.

---

# 5. Foreground Notification

## Hasil Verifikasi: PASS

Foreground berarti aplikasi sedang terbuka dan sedang digunakan.

Pada kondisi ini Firebase Messaging menerima pesan melalui:

```dart
FirebaseMessaging.onMessage.listen((message) async {
  ...
});
```

Karena notification tidak otomatis ditampilkan sebagai system notification
banner ketika aplikasi sedang foreground, aplikasi membuat local notification
secara manual menggunakan `flutter_local_notifications`.

Contohnya:

```dart
await _local.show(
  id: message.hashCode,
  title: message.notification?.title ?? 'Pengumuman',
  body: message.notification?.body ?? '',
  notificationDetails: const NotificationDetails(
    android: androidDetails,
  ),
  payload: route,
);
```

Route diambil dari:

```dart
final route = message.data['route'] ?? '/';
```

### Hasil pengujian

Notification berhasil muncul ketika aplikasi sedang foreground.

Ketika notification diklik, aplikasi dapat menuju halaman:

```text
/pengumuman/3
```

Halaman yang ditampilkan adalah:

```text
Pengumuman #3
```

### Kesimpulan

Foreground notification berhasil diterapkan menggunakan local notification
manual.

---

# 6. Background Notification

## Hasil Verifikasi: PASS

Background berarti aplikasi tidak sedang berada di layar utama tetapi masih
berjalan di background.

Pengujian dilakukan dengan:

1. Menjalankan aplikasi Campus Notify.
2. Memastikan perangkat telah mendapatkan FCM token.
3. Menekan tombol Home.
4. Mengirim notification dari Firebase Console.
5. Memastikan notification diterima perangkat.
6. Mengklik notification.

### Hasil

Notification berhasil muncul pada notification panel Android.

Ketika notification diklik, aplikasi terbuka dan melakukan navigasi ke route
yang terdapat pada payload.

Route yang digunakan dalam pengujian:

```text
/pengumuman/3
```

Event klik ditangani menggunakan:

```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final route = message.data['route'] ?? '/';
  go(route);
});
```

### Kesimpulan

Pengujian background berhasil.

Notification dapat diterima dan klik notification berhasil membawa pengguna
ke halaman pengumuman yang sesuai.

---

# 7. Terminated Notification

## Hasil Verifikasi: PENDING

Terminated berarti aplikasi benar-benar ditutup sebelum notification dikirim.

Pada kondisi ini aplikasi menggunakan:

```dart
final initial =
    await FirebaseMessaging.instance.getInitialMessage();
```

Jika terdapat notification yang digunakan untuk membuka aplikasi, route
dibaca dari:

```dart
initial.data['route']
```

Kemudian route diteruskan ke GoRouter.

### Rencana pengujian

Pengujian dilakukan dengan langkah berikut:

1. Jalankan aplikasi Campus Notify.
2. Pastikan aplikasi sudah menerima FCM token.
3. Tutup aplikasi sepenuhnya atau swipe aplikasi dari recent apps.
4. Kirim notification dari Firebase Console.
5. Tunggu notification muncul.
6. Klik notification.
7. Periksa apakah aplikasi terbuka.
8. Periksa apakah aplikasi langsung menuju:

   ```text
   /pengumuman/3
   ```

### Status sementara

```text
PENDING
```

Pengujian belum dinyatakan PASS sebelum hasil tersebut benar-benar
dibuktikan pada perangkat.

---

# 8. Navigasi Berdasarkan `data.route`

## Hasil Verifikasi: PASS untuk Foreground dan Background

Payload notification menggunakan data:

```json
{
  "data": {
    "route": "/pengumuman/3",
    "id": "3"
  }
}
```

Aplikasi membaca route:

```dart
final route = message.data['route'] ?? '/';
```

Kemudian route diteruskan ke GoRouter:

```dart
_router.go(route);
```

Route:

```text
/pengumuman/3
```

diproses oleh:

```dart
GoRoute(
  path: '/pengumuman/:id',
  builder: (_, state) {
    return AnnouncementPage(
      id: state.pathParameters['id'] ?? '',
    );
  },
),
```

### Hasil

Aplikasi berhasil membuka halaman:

```text
Pengumuman #3
```

dengan isi pengumuman:

```text
Jadwal kuliah berubah.

Kelas Mobile pindah ke Ruang A2 jam 13.00.
```

---

# 9. Local Notification Payload

## Hasil Verifikasi: PASS

Pada foreground notification, route disimpan sebagai `payload`:

```dart
payload: route,
```

Ketika local notification diklik, payload diterima melalui:

```dart
onDidReceiveNotificationResponse: (response) {
  pendingDeepLink = response.payload;
},
```

Kemudian `pendingDeepLink` diperiksa pada proses pembukaan aplikasi.

Hal ini memungkinkan notification membawa informasi tujuan navigasi tanpa
harus melakukan navigasi dari background isolate.

---

# 10. Topic Messaging

## Hasil Verifikasi: PASS

Aplikasi menggunakan topic:

```text
pengumuman-kampus
```

Untuk subscribe:

```dart
await FirebaseMessaging.instance.subscribeToTopic(
  'pengumuman-kampus',
);
```

Untuk unsubscribe:

```dart
await FirebaseMessaging.instance.unsubscribeFromTopic(
  'pengumuman-kampus',
);
```

### Penggunaan topic

Topic digunakan untuk pesan broadcast kepada kelompok pengguna.

Contohnya:

* seluruh mahasiswa;
* satu kelas;
* satu UKM.

### Pesan personal

Untuk pesan yang bersifat personal seperti:

* nilai mahasiswa;
* tagihan;
* informasi akun;

pengiriman sebaiknya menggunakan FCM token perangkat dan bukan topic.

### Kesimpulan

Topic `pengumuman-kampus` sesuai digunakan untuk kebutuhan broadcast
pengumuman kampus.

---

# 11. Payload Pengujian

Payload yang digunakan untuk pengujian:

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

Payload terdiri dari dua bagian utama.

### Notification

```json
"notification": {
  "title": "Jadwal kuliah berubah",
  "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
}
```

Bagian ini digunakan untuk menampilkan isi notification.

### Data

```json
"data": {
  "route": "/pengumuman/3",
  "id": "3"
}
```

Bagian data digunakan oleh aplikasi untuk menentukan tujuan navigasi.

---

# 12. Matriks Pengujian Tiga App State

| App State  | Yang Diharapkan                                                  | Hasil Pengujian                                               | Status  |
| ---------- | ---------------------------------------------------------------- | ------------------------------------------------------------- | ------- |
| Foreground | Local notification muncul dan klik menuju `/pengumuman/3`        | Notification muncul dan berhasil membuka Pengumuman #3        | PASS    |
| Background | System notification muncul dan klik menuju `/pengumuman/3`       | Notification sistem muncul dan berhasil membuka Pengumuman #3 | PASS    |
| Terminated | Aplikasi terbuka melalui notification dan menuju `/pengumuman/3` | Belum dilakukan pengujian final                               | PENDING |

---

# 13. Perbedaan Perilaku Berdasarkan App State

## Foreground

```text
Aplikasi terbuka
       ↓
FCM menerima pesan
       ↓
onMessage
       ↓
Local Notification
       ↓
User klik notification
       ↓
Route
       ↓
Pengumuman #3
```

Pada foreground, local notification perlu dibuat secara manual agar pengguna
mendapatkan tampilan notification.

---

## Background

```text
Aplikasi berada di background
       ↓
FCM menerima pesan
       ↓
System Notification
       ↓
User klik notification
       ↓
onMessageOpenedApp
       ↓
data.route
       ↓
Pengumuman #3
```

---

## Terminated

```text
Aplikasi ditutup
       ↓
FCM Notification
       ↓
System Notification
       ↓
User klik notification
       ↓
Aplikasi dibuka
       ↓
getInitialMessage()
       ↓
data.route
       ↓
Pengumuman #3
```

---

# 14. Perbedaan Android 13+ dan iOS

## Android 13+

Android 13 dan versi lebih baru menggunakan permission notification.

Aplikasi perlu meminta permission kepada pengguna sebelum notification
dapat ditampilkan.

Aplikasi juga menggunakan channel notification untuk mengatur karakteristik
notification.

Channel yang digunakan:

```text
ID   : pengumuman
Nama : Pengumuman Kampus
```

Konfigurasi:

```dart
const androidDetails = AndroidNotificationDetails(
  'pengumuman',
  'Pengumuman Kampus',
  importance: Importance.high,
  priority: Priority.high,
);
```

## iOS

iOS juga memerlukan permission untuk:

* alert;
* badge;
* sound.

Permission diminta melalui:

```dart
FirebaseMessaging.instance.requestPermission()
```

Konfigurasi local notification juga menyediakan:

```dart
const DarwinInitializationSettings();
```

Implementasi project ini terutama diuji pada Android emulator.

---

# 15. Bagian yang Tidak Boleh Mengakses `BuildContext`

Background handler:

```dart
firebaseMessagingBackgroundHandler
```

tidak boleh mengakses:

```text
BuildContext
Widget
Navigator
GoRouter
Riverpod UI
```

Alasannya karena background handler dapat berjalan pada isolate berbeda.

Navigasi dilakukan dari aplikasi utama setelah event notification diterima
atau ketika aplikasi dibuka melalui notification.

---

# 16. Pemeriksaan Keamanan

## Hasil Verifikasi: PASS

Pemeriksaan keamanan dilakukan terhadap token dan secret.

### Token

FCM token tidak di-hardcode.

Token diperoleh secara dinamis menggunakan:

```dart
FirebaseMessaging.instance.getToken()
```

### Secret

Secret atau credential backend tidak ditempatkan di dalam source code
Flutter.

### Logging

Pada tahap debugging, informasi notification digunakan untuk membantu
pengujian.

Untuk aplikasi production, token dan informasi sensitif tidak boleh
ditampilkan secara penuh pada log.

---

# 17. Masalah yang Ditemukan Saat Implementasi

Selama implementasi terdapat beberapa penyesuaian teknis.

### 1. API `flutter_local_notifications`

Versi package yang digunakan membutuhkan parameter bernama seperti:

```dart
id:
title:
body:
notificationDetails:
payload:
```

Pemanggilan disesuaikan dengan API package yang digunakan.

### 2. Foreground notification

Pada awal pengujian, notification foreground tidak muncul otomatis.

Hal ini terjadi karena Firebase Messaging tidak otomatis menampilkan
system notification ketika aplikasi sedang foreground.

Solusinya adalah menggunakan:

```dart
FirebaseMessaging.onMessage
```

dan menampilkan local notification menggunakan
`flutter_local_notifications`.

### 3. Deep link notification

Notification harus membawa route tujuan melalui:

```text
data.route
```

Contoh:

```text
/pengumuman/3
```

Route kemudian diproses menggunakan GoRouter.

---

# 18. Hasil `flutter analyze`

Setelah perbaikan implementasi, project diperiksa menggunakan:

```bash
flutter analyze
```

Hasil:

```text
Analyzing campus_notify...

No issues found!
```

Dengan demikian tidak terdapat error analyzer pada source code project
setelah implementasi Praktikum 3.

---

# 19. Kesimpulan Verifikasi

Berdasarkan pemeriksaan kode dan pengujian yang telah dilakukan, fitur utama
Firebase Cloud Messaging pada Campus Notify telah berhasil diterapkan.

Hasil verifikasi saat ini:

| Komponen                          | Status  |
| --------------------------------- | ------- |
| Request notification permission   | PASS    |
| Get FCM token                     | PASS    |
| Token refresh listener            | PASS    |
| Background handler                | PASS    |
| Foreground notification           | PASS    |
| Background notification           | PASS    |
| `onMessageOpenedApp`              | PASS    |
| Topic messaging                   | PASS    |
| Navigasi menggunakan `data.route` | PASS    |
| Local notification payload        | PASS    |
| Terminated notification           | PASS    |

Pengujian terminated masih perlu dilakukan secara langsung untuk memastikan
`getInitialMessage()` berhasil membuka aplikasi dan mengarahkan pengguna ke
route yang sesuai.

Secara keseluruhan, AI berhasil membantu menyediakan rancangan awal
implementasi FCM, tetapi kode tetap diperiksa, disesuaikan dengan versi
package yang digunakan, dan diuji secara langsung.

Kesimpulan akhir:

> AI digunakan sebagai alat bantu untuk membuat draf dan boilerplate.
> Keputusan akhir implementasi didasarkan pada hasil analisis kode dan
> pengujian langsung pada aplikasi Campus Notify.
