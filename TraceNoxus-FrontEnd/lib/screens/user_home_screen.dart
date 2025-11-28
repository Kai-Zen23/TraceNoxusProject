import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_requests_provider.dart';
import '../providers/message_provider.dart';
import '../providers/event_provider.dart';
import '../providers/notification_provider.dart';
import 'profile_screen.dart';


class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  XFile? _pickedImage;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = this.context;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData();
      
      final userId = userProvider.user?.id;
      if (userId != null) {
        final friendRequestsProvider = Provider.of<FriendRequestsProvider>(context, listen: false);
        friendRequestsProvider.setUserId(userId);
        friendRequestsProvider.refresh();

        final messageProvider = Provider.of<MessageProvider>(context, listen: false);
        messageProvider.loadAllConversations();

        final eventProvider = Provider.of<EventProvider>(context, listen: false);
        eventProvider.setUserId(userId);
        eventProvider.fetchEvents();

        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.setUserId(userId);
        notificationProvider.fetchNotifications();
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
      );
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _openFriends() => Navigator.pushNamed(context, '/friends');

  void _openFriendquest() => Navigator.pushNamed(context, '/friend-requests');

  void _openMessages() => Navigator.pushNamed(context, '/messages');

  void _openCalendar() => Navigator.pushNamed(context, '/calendar');

  void _openNotifications() => Navigator.pushNamed(context, '/notifications');


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final name = _nameController.text.trim();
    await userProvider.updateUserProfile(
      name: name.isEmpty ? (userProvider.user?.name ??
          userProvider.user?.username ?? '') : name,
      profileImageFile: _pickedImage,
    );
    await userProvider.loadUserData();
    if (mounted) {
      setState(() => _pickedImage = null);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
  Future<void> _switchToAdminMode(BuildContext context, AuthProvider authProvider) async {
    // Stop video to prevent disposal errors
    if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
    }

    await authProvider.switchToAdminMode();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
  }



  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/image/background_user.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F172A)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        'Trace Noxus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Serif',
                        ),
                      ),
                      const Spacer(),

                      // Role mode toggle for admins in user mode
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.canSwitchRoles && authProvider.isInUserMode) {
                            return Row(
                              children: [
                                const Text('', style: TextStyle(color: Colors.white70, fontSize: 5)),
                                const SizedBox(width: 4),
                                Switch(
                                  value: false,
                                  onChanged: (value) {
                                    if (value) _switchToAdminMode(context, authProvider);
                                  },
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.blue,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      // Friend Requests Button moved to bottom nav
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: user?.profileImageUrl != null
                              ? NetworkImage(user!.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null
                              ? const Icon(Icons.person_3_outlined, size: 20, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Highlights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Video Player Section
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _chewieController != null &&
                                  _chewieController!.videoPlayerController.value.isInitialized
                              ? VisibilityDetector(
                                  key: const Key('video-player-visibility'),
                                  onVisibilityChanged: (info) {
                                    if (info.visibleFraction > 0.5) {
                                      if (!_videoPlayerController!.value.isPlaying) {
                                        _videoPlayerController!.play();
                                      }
                                    } else {
                                      if (_videoPlayerController!.value.isPlaying) {
                                        _videoPlayerController!.pause();
                                      }
                                    }
                                  },
                                  child: Chewie(controller: _chewieController!),
                                )
                              : const Center(child: CircularProgressIndicator()),
                        ),
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4A90E2).withOpacity(0.9),
                    const Color(0xFF002F6C).withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Consumer<FriendRequestsProvider>(
                    builder: (context, provider, child) {
                      return _buildNavItem(
                        Icons.person,
                        'Friend Request',
                        () {
                          provider.markAsSeen();
                          _openFriendquest();
                        },
                        badgeCount: provider.badgeCount,
                      );
                    },
                  ),
                  Consumer<MessageProvider>(
                    builder: (context, provider, child) {
                      return _buildNavItem(
                        Icons.chat_bubble_outline,
                        'Message',
                        () {
                          provider.markAsSeen();
                          _openMessages();
                        },
                        badgeCount: provider.badgeCount,
                      );
                    },
                  ),
                  Consumer<EventProvider>(
                    builder: (context, provider, child) {
                      return _buildNavItem(
                        Icons.calendar_today,
                        'Events',
                        () {
                          provider.markAsSeen();
                          _openCalendar();
                        },
                        badgeCount: provider.badgeCount,
                      );
                    },
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      return _buildNavItem(
                        Icons.announcement,
                        'Announcement',
                        () {
                          provider.markAsSeen();
                          _openNotifications();
                        },
                        badgeCount: provider.badgeCount,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap,
      {int? badgeCount}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.2), // Highlight color
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}