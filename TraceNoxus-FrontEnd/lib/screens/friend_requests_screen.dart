import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_requests_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/styled_back_button.dart';
import 'chat_screen.dart';
import '../core/constants/app_constants.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendRequestsProvider>(context, listen: false).refresh();
      final friendPrivider =
          Provider.of<FriendProvider>(context, listen: false);
      friendPrivider.loadFriends();
      friendPrivider.loadAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendRequestsProvider>(context);
    final friendProvider = Provider.of<FriendProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/background_user.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0E1C2C)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const StyledBackButton(),
                        Expanded(
                          child: Center(
                            child: const Text(
                              'Friends',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              provider.refresh();
                              friendProvider.loadFriends();
                              friendProvider.loadAllUsers();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A90E2).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: 'My Friends'),
                        Tab(text: 'Incoming'),
                        Tab(text: 'Sent'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: provider.isLoading || friendProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            children: [
                              // My Friends
                              _FriendList(
                                friends: friendProvider.friends,
                                onUnfriend: (uid) =>
                                    friendProvider.removeFriendByUserId(uid),
                              ),
                              // Incoming
                              provider.error != null
                                  ? Center(
                                      child: Text(provider.error!,
                                          style: const TextStyle(
                                              color: Colors.white)))
                                  : _RequestsList(
                                      items: provider.incoming,
                                      type: RequestType.incoming,
                                      onAccept: (id) => provider.accept(id),
                                      onReject: (id) => provider.reject(id),
                                    ),
                              // Sent
                              provider.error != null
                                  ? Center(
                                      child: Text(provider.error!,
                                          style: const TextStyle(
                                              color: Colors.white)))
                                  : _RequestsList(
                                      items: provider.outgoing,
                                      type: RequestType.outgoing,
                                    ),
                            ],
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

enum RequestType { incoming, outgoing }

class _RequestsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final RequestType type;
  final void Function(int id)? onAccept;
  final void Function(int id)? onReject;

  const _RequestsList({
    super.key,
    required this.items,
    required this.type,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == RequestType.incoming ? Icons.inbox : Icons.outbox,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              type == RequestType.incoming
                  ? 'No pending requests'
                  : 'No sent requests',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        final id = r['id'] as int;
        // Use username if available, fallback to ID, then 'Unknown'
        final username = type == RequestType.incoming
            ? (r['sender_username']?.toString() ??
                r['sender']?.toString() ??
                'Unknown')
            : (r['receiver_username']?.toString() ??
                r['receiver']?.toString() ??
                'Unknown');

        final status = r['status']?.toString() ?? 'pending';

        return _RequestCard(
          username: username,
          status: status,
          type: type,
          onAccept: () => onAccept?.call(id),
          onReject: () => onReject?.call(id),
        );
      },
    );
  }
}

class _FriendList extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final Function(int) onUnfriend;

  const _FriendList({
    required this.friends,
    required this.onUnfriend,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final f = friends[index];
        final username = f['username']?.toString() ?? 'Unknown';
        final id = f['id'] as int;
        String? profileImage = f['profile_image'];

        // Clean up URL if needed
        if (profileImage != null) {
          if (profileImage.startsWith('file://')) {
            profileImage = profileImage.replaceAll('file://', '');
          }
          if (!profileImage.startsWith('http')) {
            profileImage = '${AppConstants.baseUrl}$profileImage';
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3156).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4A90E2), width: 2),
                  color: const Color(0xFF1E293B),
                ),
                child: ClipOval(
                  child: profileImage != null
                      ? Image.network(
                          profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.message, color: Color(0xFF4A90E2)),
                tooltip: 'Message',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(otherUserId: id),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                tooltip: 'Unfriend',
                onPressed: () => _confirmUnfriend(context, username, id),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmUnfriend(BuildContext context, String username, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3156),
        title: const Text('Unfriend', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove $username from friends?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onUnfriend(id);
            },
            child: const Text('Unfriend',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String username;
  final String status;
  final RequestType type;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _RequestCard({
    required this.username,
    required this.status,
    required this.type,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3156).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4A90E2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1E293B),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type == RequestType.incoming
                          ? '' // Empty string for incoming
                          : 'Request ${status.toLowerCase()}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (type == RequestType.incoming && status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Confirm',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
