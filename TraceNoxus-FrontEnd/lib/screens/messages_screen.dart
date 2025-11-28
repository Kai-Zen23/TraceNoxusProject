import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';
import 'chat_screen.dart';
import 'other_user_profile_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final msgProvider = Provider.of<MessageProvider>(context, listen: false);
      msgProvider.setSelf(auth);
      msgProvider.loadAllConversations();
      Provider.of<FriendProvider>(context, listen: false).loadAllUsers();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgProvider = Provider.of<MessageProvider>(context);
    final friendProvider = Provider.of<FriendProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Update self ID in case auth loaded after init
    msgProvider.setSelf(auth);

    // Filter users for the horizontal list (exclude current user and filter by search)
    final allUsers = friendProvider.allUsers.where((u) {
      final isNotMe = u['id'] != auth.currentUser?.id;
      if (!isNotMe) return false;
      
      if (_searchQuery.isEmpty) return true;
      
      final username = (u['username'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      
      return username.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/image/background_user.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Direct Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Serif',
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF3A8FB7),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2E2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3A8FB7).withValues(alpha: 0.5)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Search by username...',
                              hintStyle: TextStyle(color: Colors.white54),
                              prefixIcon: Icon(Icons.search, color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Horizontal User List (Filtered)
                if (allUsers.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: allUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final user = allUsers[index];
                        final name = (user['username'] ?? user['email'] ?? '?').toString();
                        return GestureDetector(
                          onTap: () => _showProfileOptions(context, user, friendProvider),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A8FB7),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  name,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else if (_searchQuery.isNotEmpty)
                   const Padding(
                     padding: EdgeInsets.all(16.0),
                     child: Text("No users found", style: TextStyle(color: Colors.white54)),
                   ),

                const SizedBox(height: 10),
                
                // Vertical Conversation List
                Expanded(
                  child: msgProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: msgProvider.conversations.length,
                          itemBuilder: (context, index) {
                            final convo = msgProvider.conversations[index];
                            final otherId = convo['otherId'] as int;
                            final lastMsg = convo['last'] as String;
                            
                            // Find user details
                            final user = friendProvider.allUsers.firstWhere(
                              (u) => u['id'] == otherId,
                              orElse: () => {'username': 'User $otherId', 'email': '', 'id': otherId},
                            );
                            final name = (user['username'] ?? user['email'] ?? 'User $otherId').toString().toUpperCase();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Conversation'),
                                      content: Text('Are you sure you want to delete the entire conversation with $name?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () {
                                            msgProvider.deleteConversation(otherId);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ChatScreen(otherUserId: otherId)
                                    )).then((_) {
                                      if (context.mounted) {
                                        Provider.of<MessageProvider>(context, listen: false).loadAllConversations();
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showProfileOptions(context, user, friendProvider),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3A8FB7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.person, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    lastMsg,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (convo['timestamp'] != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Text(
                                                      DateFormat('h:mm a').format((convo['timestamp'] as DateTime).toUtc().add(const Duration(hours: 8))),
                                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
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
                          },
                        ),
                ),
                // Bottom Navigation Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A8FB7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.people, color: Colors.white, size: 30),
                        onPressed: () {}, // Already on Messages
                      ),
                      IconButton(
                        icon: const Icon(Icons.public, color: Colors.white70, size: 30),
                        onPressed: () {
                          Navigator.pushNamed(context, '/general-chat');
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

  void _showProfileOptions(BuildContext context, Map<String, dynamic> user, FriendProvider friendProvider) {
    final name = (user['username'] ?? user['email'] ?? 'User').toString();
    final userId = user['id'] as int;
    final isFriend = friendProvider.friendIds.contains(userId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.white),
                title: const Text('Message', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: userId)),
                  ).then((_) {
                    if (context.mounted) {
                      Provider.of<MessageProvider>(context, listen: false).loadAllConversations();
                    }
                  });
                },
              ),
              if (!isFriend)
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.white),
                  title: const Text('Add Friend', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await friendProvider.addFriend(userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added $name as friend')),
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('View Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OtherUserProfileScreen(user: user)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}