import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/card_rarity_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import 'messages_screen.dart' show MatchEntry;
import 'profile_screen.dart' show RarityTierVisuals;

// ---------------------------------------------------------------------------
// ChatScreen
//
// Realtime 1:1 chat for a match already sitting in one of the 3 Chats
// slots (see messages_screen.dart). Backed by ChatService/ChatMessage —
// messages persist to Firestore and sync in realtime via watchMessages().
//
// Only the logged-in user's messages exist for now (see the note in
// ChatService) since matches aren't real second accounts yet — but every
// message already carries senderId, and bubbles already render on the
// left for any senderId that isn't the current uid, so nothing here
// needs to change once real two-way matching arrives.
// ---------------------------------------------------------------------------

class ChatScreen extends StatefulWidget {
  final MatchEntry match;
  const ChatScreen({super.key, required this.match});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  int _lastMessageCount = 0;

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    await ChatService.instance.sendMessage(widget.match.id, text);
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc = widget.match.tier.primaryColor;
    final myUid = AuthService.instance.currentUid;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(match: widget.match),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatService.instance.watchMessages(widget.match.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }

                  if (snapshot.hasError) {
                    // Logged so the real underlying error (e.g. a Firestore
                    // permission-denied) is visible in the console, instead
                    // of only a generic web JS-interop cast crash reaching
                    // the user.
                    debugPrint('Chat stream error: ${snapshot.error}');
                    return _ChatErrorState(error: snapshot.error);
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return _EmptyChat(name: widget.match.name);
                  }

                  // Auto-scroll to bottom whenever a new message arrives
                  // (including the realtime arrival of one we just sent).
                  if (messages.length != _lastMessageCount) {
                    _lastMessageCount = messages.length;
                    _scrollToBottom();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final isMine = m.senderId == myUid;
                      return _MessageBubble(
                        message: m,
                        isMine: isMine,
                        accent: rc,
                      );
                    },
                  );
                },
              ),
            ),
            _ComposerBar(
              controller: _controller,
              onSend: _send,
              sending: _sending,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final MatchEntry match;
  const _ChatHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    final rc = match.tier.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.panelBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.panelBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentGlow),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: rc.withOpacity(0.2),
            child: Icon(Icons.person, color: rc, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${match.tier.label} \u2022 ${match.wear.label}',
                  style: TextStyle(
                    color: rc,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────

class _ChatErrorState extends StatelessWidget {
  final Object? error;
  const _ChatErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final isPermission = error.toString().toLowerCase().contains('permission');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.danger.withOpacity(0.7),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              isPermission
                  ? "Can't load this chat right now"
                  : 'Something went wrong loading this chat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPermission
                  ? 'Your account may not have access to this conversation yet.'
                  : 'Please try again in a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textSecondary.withOpacity(0.4),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Say hi to $name',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Messages sync in realtime once sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final Color accent;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.accent,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Sending\u2026';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.accent : AppColors.panelBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: (isMine ? Colors.white : AppColors.textSecondary)
                    .withOpacity(0.6),
                fontSize: 9,
                fontStyle: message.createdAt == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Composer ─────────────────────────────────────────────────────────────

class _ComposerBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

  const _ComposerBar({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(top: BorderSide(color: AppColors.panelBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.panelBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.panelBorder),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Message\u2026',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
