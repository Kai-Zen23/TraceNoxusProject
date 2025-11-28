import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_requests_provider.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendRequestsProvider>(context);
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
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Friend Requests',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => provider.refresh(),
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: 'Incoming'),
                      Tab(text: 'Sent'),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : provider.error != null
                        ? Center(child: Text(provider.error!, style: const TextStyle(color: Colors.white)))
                        : TabBarView(
                      children: [
                        _RequestsList(
                          items: provider.incoming,
                          showActions: true,
                          onAccept: (id) => provider.accept(id),
                          onReject: (id) => provider.reject(id),
                        ),
                        _RequestsList(
                          items: provider.outgoing,
                          showActions: false,
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

class _RequestsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool showActions;
  final void Function(int id)? onAccept;
  final void Function(int id)? onReject;

  const _RequestsList({
    super.key,
    required this.items,
    required this.showActions,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No requests', style: TextStyle(color: Colors.white70)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        final r = items[index];
        final id = r['id'] as int;
        // Use username if available, fallback to ID, then 'Unknown'
        final sender = r['sender_username']?.toString() ?? r['sender']?.toString() ?? 'Unknown';
        final receiver = r['receiver_username']?.toString() ?? r['receiver']?.toString() ?? 'Unknown';
        final status = r['status']?.toString() ?? 'pending';
        
        return ListTile(
          leading: const Icon(Icons.person_add, color: Colors.white),
          title: Text(showActions ? sender : receiver, style: const TextStyle(color: Colors.white)),
          trailing: showActions && status == 'pending'
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check, color: Colors.greenAccent), onPressed: () => onAccept?.call(id)),
              IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => onReject?.call(id)),
            ],
          )
              : null,
        );
      },
    );
  }
}