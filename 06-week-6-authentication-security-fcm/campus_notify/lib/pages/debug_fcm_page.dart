import 'package:flutter/material.dart';

import '../messaging/push_service.dart';

class DebugFcmPage extends StatefulWidget {
  const DebugFcmPage({super.key});

  @override
  State<DebugFcmPage> createState() => _DebugFcmPageState();
}

class _DebugFcmPageState extends State<DebugFcmPage> {
  String _token = 'Memuat token...';
  String _permission = 'Memeriksa izin...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    try {
      await initLocalNotifications();

      final permissionGranted =
          await requestNotificationPermission();

      await initFcmToken(
        onToken: (token) async {
          if (!mounted) return;

          setState(() {
            _token = _shortenToken(token);
          });

          debugPrint('FCM Token: $token');
        },
      );

      if (!mounted) return;

      setState(() {
        _permission =
            permissionGranted ? 'Diizinkan' : 'Tidak diizinkan';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _token = 'Gagal mengambil token';
        _permission = 'Error: $e';
        _loading = false;
      });
    }
  }

  String _shortenToken(String token) {
    if (token.length <= 12) {
      return '$token...';
    }

    return '${token.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug FCM'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'FCM Debug',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Notification Permission',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_permission),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'FCM Token',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_token),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                        });
                        _initFcm();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Token'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}