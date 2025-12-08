import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:TraceNoxus/providers/room_chat_provider.dart';
import 'package:TraceNoxus/providers/friend_provider.dart';
import 'package:TraceNoxus/providers/auth_provider.dart';
import 'other_user_profile_screen.dart';

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
      final p = Provider.of<RoomChatProvider>(context, listen: false);
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoomChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final friends = Provider.of<FriendProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/image/background_user.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: const [
                      Expanded(child: Text('General Chat', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                      Icon(Icons.public, color: Colors.white),
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
                      final isMe = auth.currentUser?.id != null && m.sender == auth.currentUser!.id;
                      final user = friends.allUsers.firstWhere(
                        (u) => u['id'] == m.sender,
                        orElse: () => {'username': 'User ${m.sender}', 'id': m.sender}
                      );
                      final displayName = (m.senderName ?? user['username'] ?? user['email'] ?? 'User ${m.sender}').toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isMe)
                              GestureDetector(
                                onTap: () => _showProfile(context, user),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF2E5E88),
                                  backgroundImage: m.senderProfileImage != null ? NetworkImage(m.senderProfileImage!) : null,
                                  child: m.senderProfileImage == null
                                      ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white))
                                      : null,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                       if (!isMe) _showProfile(context, user);
                                    },
                                    child: Text(displayName,
                                        style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF3A8FB7) : const Color(0xFF2E5E88),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(m.content, style: const TextStyle(color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                                    child: Text(
                                      DateFormat('h:mm a').format(m.timestamp.toUtc().add(const Duration(hours: 8))),
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isMe)
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF3A8FB7),
                                child: Text(
                                  (auth.currentUser?.username ?? 'Me')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
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
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(24)),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
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