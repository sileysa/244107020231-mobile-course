import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/failures.dart';
import '../features/notes/domain/entities/note.dart';
import '../features/notes/presentation/providers/notes_providers.dart';
import '../features/notes/presentation/widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  bool _isSyncing = false;

  void _showFailure(Failure failure) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _addNote() async {
    final result = await showDialog<_NewNoteResult>(
      context: context,
      builder: (_) => const _AddNoteDialog(),
    );
    if (result == null || !mounted) return;

    final failure = await ref
        .read(notesProvider.notifier)
        .addNote(title: result.title, body: result.body);
    if (failure != null && mounted) _showFailure(failure);
  }

  Future<void> _deleteNote(Note note) async {
    final id = note.id;
    if (id == null) return;

    final failure = await ref.read(notesProvider.notifier).deleteNote(id);
    if (failure != null && mounted) _showFailure(failure);
  }

  Future<void> _syncNotes() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final result = await ref.read(notesProvider.notifier).syncNotes();
      if (!mounted) return;

      if (result.failure != null) {
        _showFailure(result.failure!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.synced == 0
                  ? 'Tidak ada catatan untuk disinkronkan'
                  : 'Sinkronisasi berhasil',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final notes = notesState.value ?? const <Note>[];
    final dirtyCount = notes.where((note) => note.dirty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(notesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _SyncStatus(
            dirtyCount: dirtyCount,
            isSyncing: _isSyncing,
            onSync: dirtyCount == 0 ? null : _syncNotes,
          ),
          Expanded(
            child: notesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error is Failure
                            ? error.message
                            : 'Terjadi kesalahan saat memuat catatan.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.read(notesProvider.notifier).refresh(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Belum ada catatan'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(notesProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final note = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NoteTile(
                              note: note,
                              onTap: () {
                                final id = note.id;
                                if (id != null) context.push('/note/$id');
                              },
                              onDelete: () => _deleteNote(note),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({
    required this.dirtyCount,
    required this.isSyncing,
    required this.onSync,
  });

  final int dirtyCount;
  final bool isSyncing;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final hasDirtyNotes = dirtyCount > 0;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ListTile(
        leading: Icon(
          hasDirtyNotes ? Icons.sync_problem : Icons.cloud_done_outlined,
        ),
        title: Text(
          hasDirtyNotes
              ? '$dirtyCount catatan belum tersinkron'
              : 'Semua catatan sudah tersinkron',
        ),
        subtitle: Text(
          isSyncing
              ? 'Sedang melakukan sinkronisasi...'
              : hasDirtyNotes
              ? 'Perubahan tersimpan secara lokal'
              : 'Data lokal sudah tersinkron',
        ),
        trailing: isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(onPressed: onSync, child: const Text('Sync')),
      ),
    );
  }
}

class _NewNoteResult {
  const _NewNoteResult({required this.title, required this.body});

  final String title;
  final String body;
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog();

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) return;

    Navigator.of(context).pop(_NewNoteResult(title: title, body: body));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Contoh: JS PeMob W5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Isi',
                hintText: 'Tulis isi catatan...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
