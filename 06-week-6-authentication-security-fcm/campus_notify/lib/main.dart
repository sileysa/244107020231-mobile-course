import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase.
  await Firebase.initializeApp();

  // Daftarkan background handler FCM.
  registerBackgroundHandler();

  // Inisialisasi local notification.
  await initLocalNotifications();

  // Minta izin notifikasi.
  await requestNotificationPermission();

  runApp(
    const ProviderScope(
      child: CampusNotifyApp(),
    ),
  );
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() =>
      _CampusNotifyAppState();
}

class _CampusNotifyAppState
    extends ConsumerState<CampusNotifyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      redirect: (context, state) {
        final loggedIn =
            ref.read(authStateProvider).value ?? false;

        final goingLogin =
            state.matchedLocation == AppRoutes.login;

        // Belum login tetapi mencoba membuka halaman lain.
        if (!loggedIn && !goingLogin) {
          return AppRoutes.login;
        }

        // Sudah login tetapi mencoba kembali ke halaman login.
        if (loggedIn && goingLogin) {
          return AppRoutes.home;
        }

        return null;
      },

      routes: [
        // =====================================================
        // LOGIN
        // =====================================================

        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) {
            return const LoginPage();
          },
        ),

        // =====================================================
        // HOME
        // =====================================================

        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) {
            return const HomePage();
          },
        ),

        // =====================================================
        // PENGUMUMAN
        // =====================================================

        GoRoute(
          path: AppRoutes.announcement,
          builder: (context, state) {
            return AnnouncementPage(
              id: state.pathParameters['id'] ?? '',
            );
          },
        ),
      ],
    );

    // =========================================================
    // FCM FOREGROUND + BACKGROUND CLICK
    // =========================================================

    listenForeground((route) {
      _router.go(route);
    });

    // =========================================================
    // FCM TERMINATED
    // =========================================================

    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleTerminated((route) {
        _router.go(route);
      });
    });

    // =========================================================
    // LOCAL NOTIFICATION CLICK
    // =========================================================

    onLocalNotificationTap = (route) {
      _router.go(route);
    };
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),

      routerConfig: _router,
    );
  }
}
