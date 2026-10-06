# AI Prompt Challenge — Campus Notify

## Prompt

Aplikasi Flutter Campus Notification App.

Stack:
- firebase_messaging
- flutter_local_notifications
- flutter_secure_storage
- go_router
- Riverpod

Buatkan PushService dengan fitur:

1. requestPermission
2. getToken
3. onTokenRefresh dan kirim token baru ke backend melalui POST `/devices`
4. FirebaseMessaging.onMessage untuk foreground
5. Tampilkan local notification secara manual ketika aplikasi foreground
6. FirebaseMessaging.onMessageOpenedApp untuk menangani klik notifikasi ketika background
7. getInitialMessage untuk menangani notifikasi ketika aplikasi terminated
8. subscribe/unsubscribe topic `pengumuman-kampus`
9. background handler top-level menggunakan `@pragma('vm:entry-point')`
10. Navigasi menggunakan nilai `data.route`

Tandai bagian yang berbeda untuk:
- Android 13+
- iOS

Jelaskan juga bagian yang tidak boleh mengakses:
- BuildContext
- Riverpod
- UI

Berikan perhatian khusus pada:
- lifecycle token FCM
- deep link dari notifikasi
- foreground notification
- background notification
- terminated notification
- keamanan token dan secret