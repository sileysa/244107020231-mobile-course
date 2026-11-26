import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/format.dart';
import 'features/chat/presentation/pages/chat_screen.dart';
import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/posts/presentation/pages/posts_page.dart';
import 'monitoring.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Week7HomePage(),
      routes: [
        GoRoute(
          path: 'note/:id',
          builder: (context, state) {
            final id = parseRouteId(state.pathParameters['id']);
            if (id == null) {
              return const Scaffold(
                body: Center(child: Text('ID catatan tidak valid.')),
              );
            }
            return NoteDetailPage(noteId: id);
          },
        ),
      ],
    ),
  ],
);

class Week7HomePage extends StatefulWidget {
  const Week7HomePage({super.key});

  @override
  State<Week7HomePage> createState() => _Week7HomePageState();
}

class _Week7HomePageState extends State<Week7HomePage> {
  int _currentIndex = 0;

  static const _pages = [NotesPage(), PostsPage(), ChatScreen()];

  void _showMonitoringSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Kirim event uji (Analytics)'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Monitoring.logBetaFeedbackSent();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event uji terkirim')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Kirim error non-fatal (Crashlytics)'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Monitoring.recordTestNonFatal();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error uji terkirim')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: const Text('Paksa crash uji (fatal)'),
              onTap: () {
                Navigator.pop(sheetContext);
                Monitoring.forceTestCrash();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'monitoring_fab',
        tooltip: 'Uji monitoring',
        onPressed: _showMonitoringSheet,
        child: const Icon(Icons.monitor_heart_outlined),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Catatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Asisten AI',
          ),
        ],
      ),
    );
  }
}

class Week7App extends StatelessWidget {
  const Week7App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Clean Architecture Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}