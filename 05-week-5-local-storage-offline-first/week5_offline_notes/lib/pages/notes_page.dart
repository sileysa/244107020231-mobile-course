import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/note_providers.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  List<Note> _notes = [];
  int _dirtyCount = 0;

  bool _isLoading = true;
  bool _isSyncing = false;

  NoteRepository get _repository {
    return ref.read(noteRepositoryProvider);
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _repository.fetchNotes();
      final dirtyCount = await _repository.countDirty();

      if (!mounted) return;

      setState(() {
        _notes = notes;
        _dirtyCount = dirtyCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat catatan: $e'),
        ),
      );
    }
  }

  Future<void> _addNote() async {
    final result = await showDialog<_NewNoteResult>(
      context: context,
      builder: (_) => const _AddNoteDialog(),
    );

    if (result == null) return;

    await _repository.addNote(
      title: result.title,
      body: result.body,
    );

    ref.invalidate(notesProvider);

    await _loadNotes();
  }

  Future<void> _deleteNote(Note note) async {
    if (note.id == null) return;

    await _repository.deleteNote(note.id!);

    ref.invalidate(notesProvider);

    await _loadNotes();
  }

  Future<void> _syncNotes() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await syncNotes(_repository);

      ref.invalidate(notesProvider);

      await _loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinkronisasi berhasil'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sinkronisasi gagal: $e'),
        ),
      );
    } finally {
  if (mounted) {
    setState(() {
      _isSyncing = false;
    });
  }
}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadNotes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _SyncStatus(
            dirtyCount: _dirtyCount,
            isSyncing: _isSyncing,
            onSync: _dirtyCount == 0 ? null : _syncNotes,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _notes.isEmpty
                    ? const Center(
                        child: Text('Belum ada catatan'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NoteTile(
                                note: note,
                                onTap: () {
                                  if (note.id != null) {
                                    context.push(
                                      '/note/${note.id}',
                                    );
                                  }
                                },
                                onDelete: () => _deleteNote(note),
                              ),
                            );
                          },
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
          hasDirtyNotes
              ? Icons.sync_problem
              : Icons.cloud_done_outlined,
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : TextButton(
                onPressed: onSync,
                child: const Text('Sync'),
              ),
      ),
    );
  }
}

class _NewNoteResult {
  const _NewNoteResult({
    required this.title,
    required this.body,
  });

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

    Navigator.of(context).pop(
      _NewNoteResult(
        title: title,
        body: body,
      ),
    );
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}