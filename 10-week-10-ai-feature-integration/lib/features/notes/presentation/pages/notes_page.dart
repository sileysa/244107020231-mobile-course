import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  bool _isSyncing = false;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
    await ref.read(notesProvider.future);
    await ref.read(dirtyCountProvider.future);
  }

  Future<void> _addNote() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddNoteDialog(
        onSubmit: (title, body) async {
          final result = await ref
              .read(addNoteProvider)
              .call(title: title, body: body);
          final failure = result.failure;
          if (failure is ValidationFailure) return failure.message;
          if (failure != null && mounted) {
            _showMessage('Gagal menyimpan catatan: ${failure.message}');
          }
          return null;
        },
      ),
    );

    if (added != true || !mounted) return;
    await _refresh();
  }

  Future<void> _deleteNote(Note note) async {
    final id = note.id;
    if (id == null) return;

    final failure = await ref.read(deleteNoteProvider).call(id);
    if (!mounted) return;

    if (failure != null) {
      _showMessage('Gagal menghapus catatan: ${failure.message}');
      return;
    }

    await _refresh();
  }

  Future<void> _syncNotes() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    final result = await ref.read(syncNotesProvider).call();
    await _refresh();
    if (!mounted) return;

    if (result.failure != null) {
      _showMessage('Sinkronisasi gagal: ${result.failure!.message}');
    } else {
      _showMessage('Sinkronisasi berhasil');
    }

    setState(() {
      _isSyncing = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final searchNotes = ref.watch(searchNotesProvider);
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final dirtyCount = dirtyAsync.when(
      data: (result) => result.failure == null ? result.count : null,
      error: (error, _) => null,
      loading: () => null,
    );
    final dirtyError = dirtyAsync.when(
      data: (result) => result.failure?.message,
      error: (_, _) => 'Status sinkronisasi gagal dimuat.',
      loading: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _SyncStatus(
            dirtyCount: dirtyCount,
            error: dirtyError,
            isSyncing: _isSyncing,
            onSync: dirtyCount == null || dirtyCount == 0 ? null : _syncNotes,
          ),
          _SearchField(
            controller: _searchController,
            hasQuery: _query.isNotEmpty,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _LoadError(
                message: 'Catatan gagal dimuat. Silakan coba lagi.',
                onRetry: _refresh,
              ),
              data: (result) {
                if (result.failure != null) {
                  return _LoadError(
                    message: 'Gagal memuat catatan: ${result.failure!.message}',
                    onRetry: _refresh,
                  );
                }

                final notes = result.notes;
                if (notes.isEmpty) {
                  return const Center(child: Text('Belum ada catatan'));
                }

                final visible = searchNotes(notes, _query);
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada catatan dengan judul "${_query.trim()}"',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final note = visible[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NoteTile(
                          note: note,
                          onTap: () {
                            if (note.id != null) {
                              context.push('/note/${note.id}');
                            }
                          },
                          onDelete: () => _deleteNote(note),
                        ),
                      );
                    },
                  ),
                );
              },
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

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({
    required this.dirtyCount,
    required this.error,
    required this.isSyncing,
    required this.onSync,
  });

  final int? dirtyCount;
  final String? error;
  final bool isSyncing;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final hasDirtyNotes = dirtyCount != null && dirtyCount! > 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ListTile(
        leading: Icon(
          error != null
              ? Icons.error_outline
              : hasDirtyNotes
              ? Icons.sync_problem
              : Icons.cloud_done_outlined,
        ),
        title: Text(
          error != null
              ? 'Status sinkronisasi tidak tersedia'
              : dirtyCount == null
              ? 'Memuat status sinkronisasi...'
              : hasDirtyNotes
              ? '$dirtyCount catatan belum tersinkron'
              : 'Semua catatan sudah tersinkron',
        ),
        subtitle: Text(
          isSyncing
              ? 'Sedang melakukan sinkronisasi...'
              : error ??
                    (hasDirtyNotes
                        ? 'Perubahan tersimpan secara lokal'
                        : 'Data lokal sudah tersinkron'),
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

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog({required this.onSubmit});

  /// Mengembalikan pesan error untuk kolom judul, atau null jika berhasil.
  final Future<String?> Function(String title, String body) onSubmit;

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _titleError;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final error = await widget.onSubmit(
      _titleController.text,
      _bodyController.text.trim(),
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _titleError = error;
        _isSaving = false;
      });
      return;
    }

    Navigator.of(context).pop(true);
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
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: InputDecoration(
                labelText: 'Judul',
                hintText: 'Contoh: JS PeMob W5',
                errorText: _titleError,
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
          onPressed: _isSaving ? null : _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
