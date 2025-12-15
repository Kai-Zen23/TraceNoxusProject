import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TraceNoxus/models/user_model.dart';
import 'package:TraceNoxus/providers/auth_provider.dart';
import 'package:TraceNoxus/providers/friend_provider.dart';
import 'package:TraceNoxus/providers/room_chat_provider.dart';
import 'package:TraceNoxus/core/utils/message_date_utils.dart';
import '../widgets/styled_back_button.dart';
import 'other_user_profile_screen.dart';
import 'package:TraceNoxus/core/constants/app_constants.dart';

class TeamChatScreen extends StatefulWidget {
  const TeamChatScreen({required this.config, super.key});

  final TeamChatConfig config;

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late RoomChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<FriendProvider>().loadAllUsers();

      final chat = context.read<RoomChatProvider>();
      chat.setSelf(context.read<AuthProvider>());
      // Load history first
      await chat.load(room: widget.config.channelId);
      // Then connect websocket
      if (mounted) {
        chat.connect(room: widget.config.channelId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<RoomChatProvider>();
  }

  @override
  void dispose() {
    _chatProvider.disconnect();
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

  void _showProfile(BuildContext context, Map<String, dynamic> user) {
    // If it's me, maybe show my profile? For now, do nothing or show standard profile
    // But usually this feature is for OTHER users
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtherUserProfileScreen(user: user)),
    );
  }

  void _showUnsendOptions(BuildContext context, int messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Unsend',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Remove this message for everyone',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmUnsend(context, messageId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmUnsend(BuildContext context, int messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Unsend Message?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'This message will be permanently removed for everyone in the chat.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<RoomChatProvider>(context, listen: false)
                  .deleteMessage(messageId);
              Navigator.pop(context);
            },
            child: const Text('Unsend', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

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
          orElse: () => {'username': fallback, 'id': message.sender},
        );
        final displayName =
            (message.senderName ?? friend['username'] ?? fallback).toString();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                GestureDetector(
                  onTap: () => _showProfile(context, friend),
                  child: _buildAvatar(message, friend, displayName),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      GestureDetector(
                        onTap: () {
                          if (!isMe) _showProfile(context, friend);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onLongPress: isMe
                          ? () => _showUnsendOptions(context, message.id)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF3A8FB7)
                              : const Color(0xFF2E5E88),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.content,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                      child: Text(
                        formatMessageTimestamp(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                _buildAvatar(message, friend, displayName),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(dynamic m, Map<String, dynamic> user, String displayName) {
    String? img = m.senderProfileImage ?? user['profile_image'];
    if (img != null) {
      if (img.startsWith('file://')) img = img.replaceAll('file://', '');
      if (!img.startsWith('http')) img = '${AppConstants.baseUrl}$img';
    }

    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF2E5E88),
      child: img != null
          ? ClipOval(
              child: Image.network(
                img,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text(initials,
                      style: const TextStyle(color: Colors.white));
                },
              ),
            )
          : Text(initials, style: const TextStyle(color: Colors.white)),
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
          const StyledBackButton(),
          if (config.logoAsset != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
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
            child: Center(
              child: Text(
                config.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.call,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.videocam,
              color: Colors.white,
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
    backgroundAsset: 'assets/image/background_user.png',
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
    backgroundAsset: 'assets/image/background_user.png',
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
    backgroundAsset: 'assets/image/background_user.png',
    logoAsset: 'assets/image/valo_logo.png',
    accentColor: Color(0xFFFF4655),
    allowedRoles: ['valorant', 'admin'],
    bypassAccess: true,
  ),
];
