
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/user_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart'; 
import '../providers/admin_provider.dart';

import '../providers/highlight_provider.dart';
import '../providers/announcement_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null || !user.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:  // Role Mode Switch (Admin only) - MOVED TO LEFT (Title)
          authProvider.canSwitchRoles
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: !authProvider.isInUserMode,
                     onChanged: (isAdmin) {
                      if (isAdmin) {
                         _switchToAdminMode(context, authProvider);
                      } else {
                        _showSwitchToUserDialog(context, authProvider);
                      }
                    },
                     activeColor: Colors.white,
                     activeTrackColor: Colors.blueAccent,
                     inactiveThumbColor: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authProvider.isInUserMode ? 'User Mode' : 'Admin Mode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ],
              )
            : const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent, // Transparent for background image
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode), // Swapped icon logic to match common toggle UI
            onPressed: _toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              setState(() {
                _selectedIndex = 2; // Navigate to Profile tab
              });
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout), // Changed to logout icon
             onPressed: () async {
              final navigator = Navigator.of(context);
              await authProvider.logout();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
           // Background Image
          Image.asset(
            'assets/image/background_user.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F172A)),
          ),
          // Gradient Overlay
          Container(
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
                 colors: [
                   const Color(0xFF0F172A).withOpacity(0.4),
                   const Color(0xFF0F172A).withOpacity(0.8),
                 ],
               ),
             ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: [
              AdminHomeTab(isDarkMode: _isDarkMode, onNavigate: (index) => setState(() => _selectedIndex = index)),
              const UserListScreen(),
              const ProfileScreen(),
            ],
          ),
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
                    const Color(0xFF335C81).withOpacity(0.95), // Steel Blue / Greyish Blue
                    const Color(0xFF1E3A5F).withOpacity(0.98), // Darker Blue
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  _buildCustomNavItem(0, Icons.grid_view_rounded, 'Dashboard'), // Grid icon for dashboard
                  _buildCustomNavItem(1, Icons.people_alt_rounded, 'Users'),
                  _buildCustomNavItem(2, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Role switching helper methods
  void _showSwitchToUserDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch to User Mode?'),
        content: const Text(
          'You will experience the app as a normal user. '
          'Admin features will be hidden. You can switch back to Admin Mode at any time from the toggle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.switchToUserMode();

              if (context.mounted) {
                // Navigate to user dashboard
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/user-home',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Switch to User Mode'),
          ),
        ],
      ),
    );
  }

  void _switchToAdminMode(BuildContext context, AuthProvider authProvider) async {
    await authProvider.switchToAdminMode();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switched back to Admin Mode'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class AdminHomeTab extends StatefulWidget {
  final bool isDarkMode;
  final Function(int) onNavigate;

  const AdminHomeTab({Key? key, required this.isDarkMode, required this.onNavigate}) : super(key: key);

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AdminProvider>(context, listen: false).fetchDashboardStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final user = authProvider.currentUser;

    // Use null-aware operators for safe defaults if user is null (though should be checked in parent)
    final email = user?.email ?? 'admin@example.com';
    final role = user?.role?.toUpperCase() ?? 'ADMIN';

    final stats = adminProvider.dashboardStats;
    final totalUsers = stats?['total_users']?.toString() ?? '...';
    final activeUsers = stats?['active_users']?.toString() ?? '...';
    final pendingUsers = ((stats?['total_users'] ?? 0) - (stats?['verified_users'] ?? 0)).toString();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
        left: 16.0,
        right: 16.0,
        bottom: 120.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(
            'Admin Dashboard',
            style: const TextStyle(
              fontSize: 24, // Reduced slightly to match design
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),

          // Welcome Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2E5E88).withOpacity(0.8), // Dark Blue
                      const Color(0xFF3A8FB7).withOpacity(0.6), // Lighter Blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Admin!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email: $email',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Role: ', style: TextStyle(color: Colors.white70)),
                          TextSpan(text: role, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                       style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // System Status Snapshot
          Text(
            'System Status',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          if (adminProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (adminProvider.error != null)
            Center(child: Text('Error: ${adminProvider.error}', style: const TextStyle(color: Colors.red)))
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatusCard('Total Users', totalUsers, Icons.people, Colors.blueAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusCard('Active Now', activeUsers, Icons.wifi, Colors.greenAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatusCard('Pending', pendingUsers, Icons.assignment_late_outlined, Colors.orangeAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusCard('Server', 'Online', Icons.dns, Colors.pinkAccent)),
                  ],
                ),
              ],
            ),
            
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
           const SizedBox(height: 16),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6, // Wider cards
            children: [
              _buildActionCard(context, icon: Icons.notifications_active, title: 'Send Notification', color: Colors.amber, onTap: () => _showCreateNotificationDialog(context)),
              _buildActionCard(context, icon: Icons.video_library, title: 'Manage Highlights', color: Colors.purpleAccent, onTap: () => _showUploadHighlightOptions(context)),
              _buildActionCard(context, icon: Icons.people, title: 'Manage Users', color: Colors.blue, onTap: () => Navigator.pushNamed(context, '/user-management')),
              _buildActionCard(context, icon: Icons.groups, title: 'Manage Teams', color: Colors.redAccent, onTap: () => Navigator.pushNamed(context, '/teams')),
              _buildActionCard(context, icon: Icons.calendar_month, title: 'Events', color: Colors.lightBlueAccent, onTap: () => Navigator.pushNamed(context, '/calendar')),
              _buildActionCard(context, icon: Icons.settings, title: 'Settings', color: Colors.grey, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              }),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color iconColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // Use 20 for matching curve
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 100, // Fixed height for uniformity
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.4), // Darker glass base
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column( // Use Stack or Row/Column mix to match image perfectly if needed, currently matching layout
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Icon(icon, color: iconColor, size: 28),
                   Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.4),
             borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 36, color: color),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'Enter notification title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Message', hintText: 'Enter notification message'),
                maxLines: 3,
              ),
              if (isLoading) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.isEmpty || contentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        // Use AnnouncementProvider to create Announcement + Notification + SMS
                        await Provider.of<AnnouncementProvider>(context, listen: false)
                            .addAnnouncement(titleController.text, contentController.text);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement Posted & Notification Sent!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to post announcement: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: const Text('Post'), // Changed from 'Push' to 'Post'
            ),
          ],
        ),
      ),
    );
  }

  // Highlights Logic
  void _showUploadHighlightOptions(BuildContext context) {
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
             leading: const Icon(Icons.link, color: Colors.green),
             title: const Text('Add via URL', style: TextStyle(color: Colors.white)),
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
                  decoration: const InputDecoration(labelText: 'Video URL (e.g. Cloudinary)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Game Highlights', 'Tournament Videos', 'Interview Videos']
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
                  if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                    Navigator.pop(dialogContext); // Close dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adding video link...')),
                    );
                    
                    final error = await Provider.of<HighlightProvider>(context, listen: false)
                        .uploadHighlight(
                          videoUrl: urlController.text.trim(),
                          title: titleController.text,
                          category: selectedCategory,
                        );
                        
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error == null ? 'Link added!' : error)),
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
}
