# AI Output — Campus Notify

## Ringkasan

AI menghasilkan rancangan PushService untuk menangani Firebase Cloud Messaging
pada aplikasi Campus Notify.

Fitur utama yang diusulkan:

- meminta permission notifikasi;
- mengambil FCM token;
- memantau perubahan token;
- menangani pesan foreground;
- menangani klik notifikasi ketika background;
- menangani pembukaan aplikasi dari kondisi terminated;
- subscribe dan unsubscribe topic;
- background message handler;
- navigasi berdasarkan `data.route`.

## Komponen Utama

### 1. Request Permission

Aplikasi meminta izin notifikasi melalui:

`FirebaseMessaging.instance.requestPermission()`

Permission penting terutama pada Android 13+ dan iOS.

### 2. FCM Token

Token diperoleh menggunakan:

`FirebaseMessaging.instance.getToken()`

Perubahan token dipantau menggunakan:

`FirebaseMessaging.instance.onTokenRefresh`

Token tidak boleh ditulis atau ditampilkan secara penuh pada log produksi.

### 3. Foreground

Ketika aplikasi sedang terbuka, Firebase Messaging tidak otomatis
menampilkan system notification banner.

Oleh karena itu aplikasi menggunakan:

`FirebaseMessaging.onMessage`

kemudian membuat local notification menggunakan
`flutter_local_notifications`.

Payload `data.route` digunakan sebagai tujuan navigasi ketika notifikasi
diklik.

### 4. Background

Ketika aplikasi berada di background, notification message dapat ditampilkan
oleh sistem Android.

Ketika pengguna mengklik notification, aplikasi menangani event:

`FirebaseMessaging.onMessageOpenedApp`

Kemudian aplikasi membaca:

`message.data['route']`

untuk menentukan halaman tujuan.

### 5. Terminated

Ketika aplikasi benar-benar ditutup dan dibuka melalui notification,
aplikasi mengambil pesan awal menggunakan:

`FirebaseMessaging.instance.getInitialMessage()`

Nilai `data.route` kemudian digunakan untuk melakukan navigasi.

### 6. Background Handler

Background handler harus berupa fungsi top-level:

`firebaseMessagingBackgroundHandler`

dan menggunakan:

`@pragma('vm:entry-point')`

Handler tidak boleh mengakses BuildContext, widget, atau Riverpod UI
karena handler berjalan pada isolate yang berbeda.

### 7. Topic Messaging

Aplikasi berlangganan topic:

`pengumuman-kampus`

Topic digunakan untuk pesan broadcast seperti pengumuman kepada mahasiswa.

Untuk pesan personal seperti nilai atau tagihan, token perangkat lebih tepat
digunakan daripada topic.

## Catatan

Output AI tidak langsung diterima begitu saja.

Implementasi diuji menggunakan tiga kondisi aplikasi:

1. Foreground
2. Background
3. Terminated

Beberapa bagian juga disesuaikan secara manual agar sesuai dengan versi
package Flutter yang digunakan oleh project Campus Notify.