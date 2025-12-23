import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/utils/message_date_utils.dart';
import '../widgets/styled_back_button.dart';
import 'package:TraceNoxus/providers/room_chat_provider.dart';
import 'package:TraceNoxus/providers/friend_provider.dart';
import 'package:TraceNoxus/providers/auth_provider.dart';
import 'other_user_profile_screen.dart';
import 'package:TraceNoxus/core/constants/app_constants.dart';

class GeneralChatScreen extends StatefulWidget {
  const GeneralChatScreen({super.key});
  
  @override
  State<GeneralChatScreen> createState() => _GeneralChatScreenState();
}

class _GeneralChatScreenState extends State<GeneralChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late RoomChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendProvider>(context, listen: false).loadAllUsers();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final p = Provider.of<RoomChatProvider>(context, listen: false);
      p.setSelf(auth);
      p.load(room: 'general');
      p.connect(room: 'general');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = Provider.of<RoomChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _chatProvider.disconnect();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showProfile(BuildContext context, Map<String, dynamic> user) {
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
    final provider = Provider.of<RoomChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final friends = Provider.of<FriendProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset('assets/image/background_user.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF1A1A1A)))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const StyledBackButton(),
                      Expanded(
                        child: Center(
                          child: const Text(
                            'General Chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.public, color: Colors.white),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            final m = provider.messages[index];
                            final isMe = auth.currentUser?.id != null &&
                                m.sender == auth.currentUser!.id;
                            final user = friends.allUsers.firstWhere(
                                (u) => u['id'] == m.sender,
                                orElse: () => {
                                      'username': 'User ${m.sender}',
                                      'id': m.sender
                                    });
                            final displayName = (m.senderName ??
                                    user['username'] ??
                                    user['email'] ??
                                    'User ${m.sender}')
                                .toString();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    GestureDetector(
                                      onTap: () => _showProfile(context, user),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            const Color(0xFF2E5E88),
                                        backgroundImage:
                                            m.senderProfileImage != null
                                                ? NetworkImage(
                                                    m.senderProfileImage!)
                                                : null,
                                        child: m.senderProfileImage == null
                                            ? Text(
                                                displayName.isNotEmpty
                                                    ? displayName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                    color: Colors.white))
                                            : null,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (!isMe)
                                              _showProfile(context, user);
                                          },
                                          child: Text(displayName,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10)),
                                        ),
                                        const SizedBox(height: 2),
                                  GestureDetector(
                                    onLongPress: isMe
                                        ? () => _showUnsendOptions(context, m.id)
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
                                      child: Text(m.content,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2, left: 4, right: 4),
                                    child: Text(
                                      formatMessageTimestamp(m.timestamp),
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF3A8FB7),
                                backgroundImage: m.senderProfileImage != null
                                    ? NetworkImage(m.senderProfileImage!)
                                    : (auth.currentUser?.profileImageUrl != null
                                        ? NetworkImage(
                                            auth.currentUser!.profileImageUrl!)
                                        : null),
                                child: (m.senderProfileImage == null &&
                                        auth.currentUser?.profileImageUrl == null)
                                    ? Text(
                                        (auth.currentUser?.username ?? 'Me')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      )
                                    : null,
                              ),
                            ],
                            ],
                          ),
                        );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24)),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () async {
                          final text = _controller.text.trim();
                          if (text.isEmpty) return;
                          await provider.send(text, room: 'general');
                          _controller.clear();
                          await Future.delayed(
                              const Duration(milliseconds: 100));
                          if (_scroll.hasClients)
                            _scroll.jumpTo(_scroll.position.maxScrollExtent);
                        },
                      ),
                    ],
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
