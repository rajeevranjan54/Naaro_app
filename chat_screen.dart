import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../widgets/naaro_avatar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUid;
  final String otherNickname;
  final String? otherPhotoBase64;

  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.otherNickname,
    this.otherPhotoBase64,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(ConversationModel? conv) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final chatService = context.read<ChatService>();
    final userService = context.read<UserService>();
    final myUid = userService.currentUid!;

    setState(() => _sending = true);
    _msgCtrl.clear();

    final error = await chatService.sendMessage(
      myUid: myUid,
      otherUid: widget.otherUid,
      text: text,
    );

    setState(() => _sending = false);

    if (error == 'waiting_for_reply') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for a reply before sending more.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    _scrollToBottom();
  }

  bool _canSend(ConversationModel? conv, String myUid) {
    if (conv == null) return true;
    if (conv.status == ConversationStatus.blocked ||
        conv.status == ConversationStatus.expired) return false;
    if (conv.isPending && conv.initiatorId == myUid) {
      return conv.initiatorMessageCount < AppConstants.maxPreReplyMessages;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    final myUid = context.read<UserService>().currentUid!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            NaaroAvatar(photoBase64: widget.otherPhotoBase64, radius: 18),
            const SizedBox(width: 10),
            Text(widget.otherNickname,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      body: StreamBuilder<ConversationModel?>(
        stream:
            chatService.watchConversation(myUid, widget.otherUid),
        builder: (context, convSnap) {
          final conv = convSnap.data;
          final canSend = _canSend(conv, myUid);
          final isInitiator = conv?.initiatorId == myUid;
          final msgsSent = conv?.initiatorMessageCount ?? 0;

          return Column(
            children: [
              // Status banner
              if (conv != null && conv.isPending && isInitiator)
                _PendingBanner(messagesSent: msgsSent),
              if (conv != null && conv.status == ConversationStatus.active)
                _UnlockedBanner(),

              // Messages list
              Expanded(
                child: conv == null
                    ? _buildEmptyChat()
                    : StreamBuilder<List<MessageModel>>(
                        stream: chatService.watchMessages(conv.id),
                        builder: (context, msgSnap) {
                          final msgs = msgSnap.data ?? [];
                          if (msgs.isEmpty) return _buildEmptyChat();
                          _scrollToBottom();
                          return ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: msgs.length,
                            itemBuilder: (context, i) {
                              final msg = msgs[i];
                              final isMe = msg.senderId == myUid;
                              return _MessageBubble(
                                message: msg,
                                isMe: isMe,
                              ).animate().fadeIn(delay: (i * 30).ms);
                            },
                          );
                        },
                      ),
              ),

              // Input area
              _InputBar(
                controller: _msgCtrl,
                enabled: canSend && !_sending,
                locked: !canSend,
                onSend: () => _send(conv),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.waving_hand_rounded,
                size: 44, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Say hello to ${widget.otherNickname}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You can send up to ${AppConstants.maxPreReplyMessages} intro messages.\nFull chat unlocks when they reply.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  final int messagesSent;
  const _PendingBanner({required this.messagesSent});

  @override
  Widget build(BuildContext context) {
    final remaining = AppConstants.maxPreReplyMessages - messagesSent;
    return Container(
      width: double.infinity,
      color: AppTheme.primary.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded,
              size: 16, color: AppTheme.primaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              remaining > 0
                  ? 'You can send $remaining more intro message${remaining == 1 ? '' : 's'} before they reply.'
                  : 'Waiting for their reply to unlock the conversation…',
              style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.accent.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Icon(Icons.lock_open_rounded, size: 14, color: AppTheme.accent),
          SizedBox(width: 8),
          Text(
            'Conversation unlocked — enjoy chatting!',
            style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : AppTheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(message.timestamp, locale: 'en_short'),
                    style: TextStyle(
                      color: (isMe ? Colors.white : AppTheme.onSurface)
                          .withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool locked;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.locked,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _charCount = widget.controller.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return Container(
        color: AppTheme.surface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 16, color: AppTheme.onSurfaceMuted),
            const SizedBox(width: 8),
            Text(
              'Waiting for response…',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.onSurfaceMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: widget.controller,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: AppConstants.maxMessageCharacters,
                  enabled: widget.enabled,
                  style: const TextStyle(color: AppTheme.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixText: '$_charCount/${AppConstants.maxMessageCharacters}',
                    suffixStyle: const TextStyle(
                        color: AppTheme.onSurfaceMuted, fontSize: 11),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSend(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.enabled ? widget.onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.enabled && _charCount > 0
                    ? AppTheme.primary
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.send_rounded,
                color: widget.enabled && _charCount > 0
                    ? Colors.white
                    : AppTheme.onSurfaceMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
