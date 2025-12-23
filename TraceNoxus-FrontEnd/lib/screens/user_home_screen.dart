import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_requests_provider.dart';
import '../providers/message_provider.dart';
import '../providers/event_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/announcement_provider.dart';
import '../widgets/highlights_section.dart';
import 'profile_screen.dart';
import '../providers/highlight_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  XFile? _pickedImage;
  // Video controllers removed as they are now managed by HighlightsSection

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = this.context;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData();

      final userId = userProvider.user?.id;
      if (userId != null) {
        final friendRequestsProvider =
            Provider.of<FriendRequestsProvider>(context, listen: false);
        friendRequestsProvider.setUserId(userId);
        friendRequestsProvider.refresh();

        final messageProvider =
            Provider.of<MessageProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        messageProvider.setSelf(authProvider);
        messageProvider.loadAllConversations();

        final eventProvider =
            Provider.of<EventProvider>(context, listen: false);
        eventProvider.setUserId(userId);
        eventProvider.fetchEvents();

        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.setUserId(userId);
        notificationProvider.fetchNotifications();

        final announcementProvider =
            Provider.of<AnnouncementProvider>(context, listen: false);
        announcementProvider.setUserId(userId);
        announcementProvider.fetchAnnouncements();
      }
    });
  }

  bool _isPickingVideo = false;

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.video_library, color: Colors.blue),
            title: const Text('Upload from Gallery',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickVideoFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.green),
            title: const Text('Add via URL',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showUrlUploadDialog();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickVideoFromGallery() async {
    if (_isPickingVideo) return;

    setState(() {
      _isPickingVideo = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null && mounted) {
        final TextEditingController titleController = TextEditingController();
        String selectedCategory = 'Game Highlights';

        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Upload Highlight'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Video Title'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: [
                    'Game Highlights',
                    'Tournament Videos',
                    'Interview Videos'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => selectedCategory = val!,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    Navigator.pop(
                        dialogContext); // Close dialog using dialogContext

                    // Show loading using outer context
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uploading video...')),
                    );

                    // Use outer context for Provider as well
                    final error = await Provider.of<HighlightProvider>(context,
                            listen: false)
                        .uploadHighlight(
                      videoFile: File(video.path),
                      title: titleController.text,
                      category: selectedCategory,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(error == null ? 'Upload proper!' : error)),
                      );
                    }
                  }
                },
                child: const Text('Upload'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error picking video. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingVideo = false;
        });
      }
    }
  }

  Future<void> _showUrlUploadDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    String selectedCategory = 'Game Highlights';

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Highlight Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Video Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                  labelText: 'Video URL (e.g. Cloudinary)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: [
                'Game Highlights',
                'Tournament Videos',
                'Interview Videos'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => selectedCategory = val!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                Navigator.pop(dialogContext); // Close dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adding video link...')),
                );

                final error =
                    await Provider.of<HighlightProvider>(context, listen: false)
                        .uploadHighlight(
                  videoUrl: urlController.text.trim(),
                  title: titleController.text,
                  category: selectedCategory,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(error == null ? 'Link added!' : error)),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openFriends() => Navigator.pushNamed(context, '/friends');

  void _openFriendquest() => Navigator.pushNamed(context, '/friend-requests');

  void _openMessages() => Navigator.pushNamed(context, '/messages');

  void _openCalendar() => Navigator.pushNamed(context, '/calendar');

  void _openNotifications() => Navigator.pushNamed(context, '/announcement');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final name = _nameController.text.trim();
    await userProvider.updateUserProfile(
      name: name.isEmpty
          ? (userProvider.user?.name ?? userProvider.user?.username ?? '')
          : name,
      profileImageFile: _pickedImage,
    );
    await userProvider.loadUserData();
    if (mounted) {
      setState(() => _pickedImage = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _switchToAdminMode(
      BuildContext context, AuthProvider authProvider) async {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                          if (authProvider.canSwitchRoles &&
                              authProvider.isInUserMode) {
                            return Row(
                              children: [
                                const Text('',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 5)),
                                const SizedBox(width: 4),
                                Switch(
                                  value: false,
                                  onChanged: (value) {
                                    if (value)
                                      _switchToAdminMode(context, authProvider);
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: user?.profileImageUrl != null
                              ? NetworkImage(user!.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null
                              ? const Icon(Icons.person_3_outlined,
                                  size: 20, color: Colors.white)
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

                        // New Highlights Section
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            final isAdmin = auth.user?.role == 'admin' ||
                                auth.user?.isStaff == true;
                            return HighlightsSection(
                              isAdmin: isAdmin,
                              onUpload: _showUploadOptions, // Updated callback
                            );
                          },
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
          // Custom Bottom Navigation Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4A90E2).withOpacity(0.9),
                    const Color(0xFF002F6C).withOpacity(0.9),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  Consumer<AnnouncementProvider>(
                    builder: (context, provider, child) {
                      return _buildNavItem(
                        Icons.announcement,
                        'Announcement',
                        () {
                          provider.markAsSeen();
                          _openNotifications(); // This opens AnnouncementScreen
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
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: Colors.white70,
                  size: 28,
                ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
