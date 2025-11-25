import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TraceNoxus/models/user_model.dart';
import 'package:TraceNoxus/providers/auth_provider.dart';
import 'package:TraceNoxus/providers/friend_provider.dart';
import 'package:TraceNoxus/providers/room_chat_provider.dart';

class TeamChatScreen extends StatefulWidget {
  const TeamChatScreen({required this.config, super.key});

  final TeamChatConfig config;

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<FriendProvider>()
          .loadAllUsers(); // ensure avatars have display names
      context.read<RoomChatProvider>().load(room: widget.config.channelId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<RoomChatProvider>();
    final friends = context.watch<FriendProvider>();
    final canAccess = widget.config.hasAccess(auth.currentUser);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              widget.config.backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1828), Color(0xFF102844)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          SafeArea(
            child: Column(
              children: [
                _TeamChatHeader(config: widget.config),
                const SizedBox(height: 8),
                Expanded(
                  child: canAccess
                      ? _ChatListView(
                          chat: chat,
                          friends: friends,
                          auth: auth,
                          scrollController: _scrollController,
                        )
                      : _LockedChatMessage(config: widget.config),
                ),
                _Composer(
                  controller: _messageController,
                  enabled: canAccess && !chat.isLoading,
                  onSend: (text) async {
                    await chat.send(text, room: widget.config.channelId);
                    _messageController.clear();
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView({
    required this.chat,
    required this.friends,
    required this.auth,
    required this.scrollController,
  });

  final RoomChatProvider chat;
  final FriendProvider friends;
  final AuthProvider auth;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (chat.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF88AEC9)),
      );
    }

    if (chat.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Be the first to start the conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final isMe =
            auth.currentUser != null && message.sender == auth.currentUser!.id;
        final fallback = 'User ${message.sender}';
        final friend = friends.allUsers.firstWhere(
          (u) => u['id'] == message.sender,
          orElse: () => {'username': fallback},
        );
        final displayName =
            (message.senderName ?? friend['username'] ?? fallback).toString();

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF4BA3C3).withOpacity(0.9)
                  : Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final Future<void> Function(String message) onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: enabled ? () {} : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Type here...'
                    : 'You need access to send messages',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontStyle: enabled ? FontStyle.normal : FontStyle.italic,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: enabled
                  ? (value) {
                      final text = value.trim();
                      if (text.isNotEmpty) onSend(text);
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6DA7CE), Color(0xFF2E4C6D)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: enabled
                  ? () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) onSend(text);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamChatHeader extends StatelessWidget {
  const _TeamChatHeader({required this.config});

  final TeamChatConfig config;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF88AEC9),
              size: 32,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (config.logoAsset != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 36,
                height: 36,
                child: ClipOval(
                  child: Image.asset(
                    config.logoAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white24,
                      alignment: Alignment.center,
                      child: Text(
                        config.name.characters.first,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text(
              config.name,
              style: const TextStyle(
                color: Color(0xFF88AEC9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.call,
              color: Color(0xFF88AEC9),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.videocam,
              color: Color(0xFF88AEC9),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _LockedChatMessage extends StatelessWidget {
  const _LockedChatMessage({required this.config});

  final TeamChatConfig config;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: Colors.white70, size: 36),
            const SizedBox(height: 16),
            Text(
              '${config.name} is restricted.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Only members with roles ${config.allowedRoles.join(', ')} can participate.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TeamChatConfig {
  const TeamChatConfig({
    required this.id,
    required this.name,
    required this.channelId,
    required this.backgroundAsset,
    required this.accentColor,
    this.logoAsset,
    this.allowedRoles = const [],
    this.bypassAccess = false,
  });

  final String id;
  final String name;
  final String channelId;
  final String backgroundAsset;
  final Color accentColor;
  final String? logoAsset;
  final List<String> allowedRoles;
  final bool bypassAccess;

  bool hasAccess(UserModel? user) {
    if (bypassAccess) return true;
    if (user == null) return false;
    if (allowedRoles.isEmpty) return true;
    final role = user.role.toLowerCase();
    return allowedRoles.any((allowed) => allowed.toLowerCase() == role);
  }
}

const List<TeamChatConfig> teamChatConfigs = [
  TeamChatConfig(
    id: 'codm',
    name: 'COD: Mobile',
    channelId: 'team_cod_mobile',
    backgroundAsset: 'assets/image/Background.png',
    logoAsset: 'assets/image/codmlogo.png',
    accentColor: Color(0xFF5DA7C2),
    allowedRoles: ['cod', 'admin'],
    bypassAccess: true,
  ),
  TeamChatConfig(
    id: 'dota',
    name: 'Dota 2',
    channelId: 'team_dota',
    backgroundAsset: 'assets/image/backgrounduser.png',
    logoAsset: 'assets/image/dotalogo.png',
    accentColor: Color(0xFFC54B30),
    allowedRoles: ['dota', 'admin'],
    bypassAccess: true,
  ),
  TeamChatConfig(
    id: 'lol',
    name: 'League of Legends',
    channelId: 'team_lol',
    backgroundAsset: 'assets/image/Background.png',
    logoAsset: 'assets/image/lol_logo.png',
    accentColor: Color(0xFFC89B3C),
    allowedRoles: ['lol', 'admin'],
    bypassAccess: true,
  ),
  TeamChatConfig(
    id: 'mlbb',
    name: 'Mobile Legends',
    channelId: 'team_mlbb',
    backgroundAsset: 'assets/image/backgrounduser.png',
    logoAsset: 'assets/image/ml_logo.png',
    accentColor: Color(0xFFE63946),
    allowedRoles: ['ml', 'admin'],
    bypassAccess: true,
  ),
  TeamChatConfig(
    id: 'tekken',
    name: 'Tekken 8',
    channelId: 'team_tekken',
    backgroundAsset: 'assets/image/Background.png',
    logoAsset: 'assets/image/tekken.png',
    accentColor: Color(0xFFFF6B35),
    allowedRoles: ['tekken', 'admin'],
    bypassAccess: true,
  ),
  TeamChatConfig(
    id: 'valorant',
    name: 'Valorant',
    channelId: 'team_valorant',
    backgroundAsset: 'assets/image/backgrounduser.png',
    logoAsset: 'assets/image/valo_logo.png',
    accentColor: Color(0xFFFF4655),
    allowedRoles: ['valorant', 'admin'],
    bypassAccess: true,
  ),
];

