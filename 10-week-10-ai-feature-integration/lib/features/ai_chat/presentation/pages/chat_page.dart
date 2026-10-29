import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai_chat_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/ai_chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _lastPrompt = '';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(aiChatProvider);
    final keyStatus = ref.watch(apiKeyConfiguredProvider);
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.messages.lastOrNull?.text !=
              next.messages.lastOrNull?.text) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Kampus AI'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan API key',
            onPressed: _showApiKeyDialog,
            icon: const Icon(Icons.key_outlined),
          ),
          IconButton(
            tooltip: 'Hapus percakapan',
            onPressed: chat.isSending
                ? null
                : ref.read(aiChatProvider.notifier).clearConversation,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          _PrivacyNotice(),
          keyStatus.when(
            data: (configured) => _ApiKeyStatus(
              configured: configured,
              onConfigure: _showApiKeyDialog,
            ),
            error: (_, _) => const _InlineNotice(
              message: 'Status API key tidak dapat dibaca.',
            ),
            loading: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: chat.messages.isEmpty
                ? const _WelcomeMessage()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = chat.messages[index];
                      return _MessageBubble(
                        message: message,
                        showTyping:
                            chat.isSending &&
                            index == chat.messages.length - 1 &&
                            message.text.isEmpty,
                      );
                    },
                  ),
          ),
          if (chat.errorMessage case final error?)
            _ChatError(
              message: error,
              onRetry: _lastPrompt.isEmpty ? null : () => _send(_lastPrompt),
            ),
          _MessageComposer(
            controller: _messageController,
            enabled: !chat.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    _lastPrompt = text;
    _messageController.clear();
    await ref.read(aiChatProvider.notifier).send(text);
  }

  Future<void> _showApiKeyDialog() async {
    final controller = TextEditingController();
    final action = await showDialog<_ApiKeyAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'API key',
            hintText: 'Tempel API key Gemini',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ApiKeyAction.cancel),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ApiKeyAction.delete),
            child: const Text('Hapus key'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ApiKeyAction.save),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final apiKey = controller.text;
    controller.dispose();

    if (!mounted || action == null || action == _ApiKeyAction.cancel) return;

    try {
      if (action == _ApiKeyAction.save) {
        await ref.read(aiChatRepositoryProvider).saveApiKey(apiKey);
      } else {
        await ref.read(aiChatRepositoryProvider).deleteApiKey();
      }
      ref.invalidate(apiKeyConfiguredProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == _ApiKeyAction.save
                  ? 'API key disimpan di penyimpanan aman perangkat.'
                  : 'API key telah dihapus.',
            ),
          ),
        );
      }
    } on AiChatFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }
}

enum _ApiKeyAction { cancel, save, delete }

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Jangan kirim NIK, nomor telepon, email, alamat, atau data '
              'sensitif. Pesan dikirim ke Google Gemini dan tidak disimpan '
              'di riwayat lokal.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyStatus extends StatelessWidget {
  const _ApiKeyStatus({required this.configured, required this.onConfigure});

  final bool configured;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    if (configured) return const SizedBox.shrink();
    return _InlineNotice(
      message: 'Atur API key untuk mulai menggunakan chat.',
      action: TextButton(
        onPressed: onConfigure,
        child: const Text('Atur API key'),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 12)),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Ada yang ingin ditanyakan?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tanyakan hal umum seputar kegiatan kampus. '
              'Jawaban AI dapat keliru, jadi periksa kembali informasi penting.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.showTyping = false});

  final ChatMessage message;
  final bool showTyping;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? colors.primaryContainer : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: showTyping
            ? const SizedBox(
                width: 36,
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : SelectableText(message.text),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 4),
          Text(
            'Fallback: coba lagi saat koneksi pulih atau gunakan catatan '
            'lokal di tab Catatan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onRetry != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: 1200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Tulis pertanyaan...',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: enabled ? onSend : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Kirim pertanyaan',
              onPressed: enabled ? () => onSend(controller.text) : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
