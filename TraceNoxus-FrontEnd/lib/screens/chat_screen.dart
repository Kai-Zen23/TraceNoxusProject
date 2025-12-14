import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/message_date_utils.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';

import '../providers/friend_provider.dart';
import 'package:TraceNoxus/core/constants/app_constants.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  const ChatScreen({super.key, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late MessageProvider _messageProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<MessageProvider>(context, listen: false);
      provider.setSelf(auth);
      provider.loadChat(widget.otherUserId);
      provider.connect(widget.otherUserId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageProvider = Provider.of<MessageProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _messageProvider.disconnect();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final friendProvider = Provider.of<FriendProvider>(context);
    final me = auth.currentUser?.id ?? 0;

    // Find user details for header
    final user = friendProvider.allUsers.firstWhere(
      (u) => u['id'] == widget.otherUserId,
      orElse: () => {'username': 'User ${widget.otherUserId}', 'email': '', 'id': widget.otherUserId},
    );
    final name = (user['username'] ?? user['email'] ?? 'User ${widget.otherUserId}').toString();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/image/background_user.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A))),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
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
                      final isMe = m.sender == me;
                      return GestureDetector(
                        onLongPress: isMe ? () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Message'),
                              content: const Text('Are you sure you want to delete this message?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteMessage(m.id);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        } : null,
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                _buildProfileImage(m, user),
                              if (!isMe)
                                const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF2B4267) : const Color(0xFF2E5E88),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(m.content, style: const TextStyle(color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      formatMessageTimestamp(m.timestamp),
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF3A8FB7),
                                  backgroundImage: m.senderProfileImage != null 
                                      ? NetworkImage(m.senderProfileImage!) 
                                      : (auth.currentUser?.profileImageUrl != null 
                                          ? NetworkImage(auth.currentUser!.profileImageUrl!) 
                                          : null),
                                  child: (m.senderProfileImage == null && auth.currentUser?.profileImageUrl == null)
                                      ? Text((auth.currentUser?.username ?? 'Me')[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white))
                                      : null,
                                ),
                              ],
                            ],
                          ),
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
                          await provider.send(receiverId: widget.otherUserId, content: text);
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
  Widget _buildProfileImage(dynamic m, Map<String, dynamic> user) {
    String? otherImage = m.senderProfileImage ?? user['profile_image'];
    if (otherImage != null) {
      if (otherImage.startsWith('file://')) otherImage = otherImage.replaceAll('file://', '');
      if (!otherImage.startsWith('http')) otherImage = '${AppConstants.baseUrl}$otherImage';
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[800],
      backgroundImage: otherImage != null ? NetworkImage(otherImage) : null,
      child: otherImage == null ? const Icon(Icons.person, color: Colors.white, size: 16) : null,
    );
  }
}