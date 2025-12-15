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

    // Split users
    final myFriends = friends.allUsers
        .where((u) => friends.friendIds.contains(u['id']))
        .toList();
    final exploreUsers = friends.allUsers
        .where((u) => !friends.friendIds.contains(u['id']))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/image/background_user.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1A1A1A)),
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
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(Icons.group, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/friend-requests'),
                        child: const Text('View Requests',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      tabs: [
                        Tab(text: 'My Friends'),
                        Tab(text: 'Explore'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (friends.isLoading || requests.isLoading)
                      const Expanded(
                          child: Center(child: CircularProgressIndicator()))
                    else
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 1. My Friends Tab
                            myFriends.isEmpty
                                ? const Center(
                                    child: Text('No friends yet.',
                                        style: TextStyle(color: Colors.white70)))
                                : ListView.separated(
                                    itemCount: myFriends.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(color: Colors.white24),
                                    itemBuilder: (context, index) {
                                      final u = myFriends[index];
                                      final id = u['id'] as int;
                                      return ListTile(
                                        leading: const Icon(Icons.person,
                                            color: Colors.white),
                                        title: Text(
                                            u['username'] ??
                                                u['email'] ??
                                                'User',
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        subtitle: Text('ID: $id',
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chat,
                                                  color: Colors.white),
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            ChatScreen(
                                                                otherUserId:
                                                                    id)));
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.person_remove,
                                                  color: Colors.redAccent),
                                              onPressed: () {
                                                friends
                                                    .removeFriendByUserId(id);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                            // 2. Explore Tab
                            exploreUsers.isEmpty
                                ? const Center(
                                    child: Text('No new users to find.',
                                        style: TextStyle(color: Colors.white70)))
                                : ListView.separated(
                                    itemCount: exploreUsers.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(color: Colors.white24),
                                    itemBuilder: (context, index) {
                                      final u = exploreUsers[index];
                                      final id = u['id'] as int;
                                      
                                      // Check if there is a pending request for this user
                                      // Incoming: I have a request FROM them (Status: Pending) -> Show Accept/Reject (or just 'request received')
                                      // Outgoing: I have SENT a request TO them (Status: Pending) -> Show 'Pending' icon
                                      bool isPendingOutgoing = requests.outgoing.any((r) => r['receiver'] == id && r['status'] == 'pending');
                                      bool isPendingIncoming = requests.incoming.any((r) => r['sender'] == id && r['status'] == 'pending');

                                      return ListTile(
                                        leading: const Icon(Icons.person,
                                            color: Colors.white),
                                        title: Text(
                                            u['username'] ??
                                                u['email'] ??
                                                'User',
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        subtitle: Text('ID: $id',
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                        trailing: isPendingOutgoing
                                            ? const Icon(Icons.schedule, color: Colors.white70) // Sent
                                            : isPendingIncoming
                                                ? const Text('Request Received', style: TextStyle(color: Colors.greenAccent, fontSize: 12)) // Received (Action in Requests screen)
                                                : IconButton(
                                                    icon: const Icon(
                                                        Icons.person_add,
                                                        color: Colors.white),
                                                    onPressed: () =>
                                                        requests.sendRequest(id),
                                                  ),
                                      );
                                    },
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
      ),
    );
  }
}