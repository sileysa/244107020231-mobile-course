import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';
import 'package:week7_clean_architecture/features/posts/domain/entities/post.dart';
import 'package:week7_clean_architecture/features/posts/domain/repositories/posts_repository.dart';
import 'package:week7_clean_architecture/features/posts/presentation/providers/posts_providers.dart';
import 'package:week7_clean_architecture/routes.dart';

import 'fakes/fake_note_repository.dart';

void main() {
  testWidgets('Offline Notes app berhasil ditampilkan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          postsRepositoryProvider.overrideWithValue(_FakePostsRepository()),
        ],
        child: const Week7App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Catatan Offline'), findsOneWidget);
    expect(find.text('Belum ada catatan'), findsOneWidget);
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Posts'), findsOneWidget);

    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();

    expect(find.text('Offline Posts'), findsOneWidget);
    expect(find.text('Force Offline'), findsOneWidget);

    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan Offline'), findsOneWidget);
  });
}

class _FakePostsRepository implements PostsRepository {
  @override
  Future<PostsResult> fetchPosts({required bool forceOffline}) async {
    return (posts: const <Post>[], failure: null, fromCache: forceOffline);
  }
}
