import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../providers/friend_requests_provider.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendProvider>(context, listen: false).loadAllUsers();
      Provider.of<FriendProvider>(context, listen: false).loadFriends();
      Provider.of<FriendRequestsProvider>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final friends = Provider.of<FriendProvider>(context);
    final requests = Provider.of<FriendRequestsProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/background_user.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Friends',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.group, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/friend-requests'),
                      child: const Text('View Requests', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (friends.isLoading || requests.isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: friends.allUsers.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                        itemBuilder: (context, index) {
                          final u = friends.allUsers[index];
                          final id = u['id'] as int;
                          final isFriend = friends.friendIds.contains(id);
                          bool isPendingOutgoing = requests.outgoing.any((r) => r['receiver'] == id && r['status'] == 'pending');
                          Map<String, dynamic>? incoming;
                          try {
                            incoming = requests.incoming.firstWhere((r) => r['sender'] == id && r['status'] == 'pending');
                          } catch (_) {
                            incoming = null;
                          }
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: Text(u['username'] ?? u['email'] ?? 'User', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('ID: $id', style: const TextStyle(color: Colors.white70)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isFriend) ...[
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Colors.white),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: id)));
                                    },
                                  ),
                                ] else if (incoming != null) ...[
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.greenAccent),
                                    onPressed: () => requests.accept(incoming!['id'] as int),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.redAccent),
                                    onPressed: () => requests.reject(incoming!['id'] as int),
                                  ),
                                ] else if (isPendingOutgoing) ...[
                                  const Icon(Icons.schedule, color: Colors.white70),
                                ] else ...[
                                  IconButton(
                                    icon: const Icon(Icons.person_add, color: Colors.white),
                                    onPressed: () => requests.sendRequest(id),
                                  ),
                                ]
                              ],
                            ),
                          );
                        },
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