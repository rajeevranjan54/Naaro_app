import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_theme.dart';
import '../../widgets/naaro_avatar.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/user_service.dart';
import '../../../data/models/user_model.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    final userService = context.read<UserService>();
    final myUid = userService.currentUid!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                'Messages',
                style:
                    Theme.of(context).textTheme.displayMedium?.copyWith(
                          letterSpacing: -0.5,
                        ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ConversationModel>>(
                stream: chatService.watchMyConversations(myUid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final convs = snap.data ?? [];
                  if (convs.isEmpty) return _buildEmpty(context);

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: convs.length,
                    itemBuilder: (context, i) {
                      return _ConvTile(
                        conv: convs[i],
                        myUid: myUid,
                        userService: userService,
                      ).animate().fadeIn(delay: (i * 50).ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 52, color: AppTheme.onSurfaceMuted),
            const SizedBox(height: 20),
            Text('No conversations yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Go to Nearby to discover and message people around you.',
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

class _ConvTile extends StatefulWidget {
  final ConversationModel conv;
  final String myUid;
  final UserService userService;

  const _ConvTile(
      {required this.conv,
      required this.myUid,
      required this.userService});

  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile> {
  UserModel? _other;

  @override
  void initState() {
    super.initState();
    _loadOther();
  }

  Future<void> _loadOther() async {
    final otherId = widget.conv.participantIds
        .firstWhere((id) => id != widget.myUid, orElse: () => '');
    if (otherId.isEmpty) return;
    final user = await widget.userService.getUser(otherId);
    if (mounted) setState(() => _other = user);
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conv;
    final unread = conv.unreadCounts[widget.myUid] ?? 0;
    final isPending = conv.isPending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _other == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUid: _other!.uid,
                      otherNickname: _other!.nickname,
                      otherPhotoBase64: _other!.photoBase64,
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  NaaroAvatar(photoBase64: _other?.photoBase64, radius: 26),
                  if (unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _other?.nickname ?? '…',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conv.lastMessageAt != null)
                          Text(
                            timeago.format(conv.lastMessageAt!,
                                locale: 'en_short'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (isPending)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            conv.lastMessageText ?? 'Start the conversation',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: unread > 0
                                      ? AppTheme.onSurface
                                      : AppTheme.onSurfaceMuted,
                                  fontWeight: unread > 0
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
