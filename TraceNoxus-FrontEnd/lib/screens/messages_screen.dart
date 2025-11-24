// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\screens\messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessageProvider>(context, listen: false).loadConversation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/backgrounduser.png',
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
                    children: [
                      const Expanded(
                        child: Text(
                          'Messages',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () => provider.loadConversation(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.public, color: Colors.white),
                    title: const Text('General Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Chat with everyone', style: TextStyle(color: Colors.white70)),
                    onTap: () => Navigator.pushNamed(context, '/general-chat'),
                  ),
                  const Divider(color: Colors.white24),
                  if (provider.isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (provider.error != null)
                    Expanded(child: Center(child: Text(provider.error!, style: const TextStyle(color: Colors.white))))
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: provider.conversations.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                        itemBuilder: (context, index) {
                          final convo = provider.conversations[index];
                          final otherId = convo['otherId'] as int;
                          final last = convo['last'] as String;
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.white),
                            title: Text('User $otherId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: otherId)));
                            },
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