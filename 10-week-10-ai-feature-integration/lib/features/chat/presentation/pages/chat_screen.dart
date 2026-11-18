import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_notifier.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).send(text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(
        _scroll.position.maxScrollExtent
      );
    });
  }

  Future<void> _showApiKeyDialog() async {
    final keyController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur API key'),
        content: TextField(
          controller: keyController,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Gemini API key'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    final key = keyController.text;
    keyController.dispose();
    if (saved != true) return;

    final failure = await ref.read(saveAiApiKeyProvider).call(key);
    messenger.showSnackBar(
      SnackBar(content: Text(failure?.message ?? 'API key tersimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    ref.listen(chatProvider, (_, _) => _scrollToEnd());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten AI'),
        actions: [
          IconButton(
            tooltip: 'Atur API key',
            icon: const Icon(Icons.key),
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            tooltip: 'Hapus percakapan',
            icon: const Icon(Icons.delete_outline),
            onPressed: chat.messages.isEmpty || chat.isLoading
                ? null
                : () => ref.read(chatProvider.notifier).clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chat.messages.isEmpty
                  ? const Center(child: Text('Tanyakan sesuatu pada asisten.'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: chat.messages.length,
                      itemBuilder: (_, i) =>
                          _Bubble(message: chat.messages[i]),
                    ),
            ),
            if (chat.isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Asisten sedang mengetik...'),
                  ],
                ),
              ),
            if (chat.failure != null)
              _ErrorBanner(
                failure: chat.failure!,
                onRetry: () => ref.read(chatProvider.notifier).retry(),
                onSetKey: _showApiKeyDialog,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: SendChatMessage.maxLength,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Kirim',
                    icon: const Icon(Icons.send),
                    onPressed: chat.isLoading ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fromUser = message.fromUser;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: fromUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(message.text),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.failure,
    required this.onRetry,
    required this.onSetKey,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final VoidCallback onSetKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final needsKey = failure is AuthenticationFailure;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              failure.message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: needsKey ? onSetKey : onRetry,
            child: Text(needsKey ? 'Atur key' : 'Coba lagi'),
          ),
        ],
      ),
    );
  }
}