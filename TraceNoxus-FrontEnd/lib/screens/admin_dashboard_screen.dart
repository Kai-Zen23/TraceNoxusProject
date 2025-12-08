import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/user_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart'; 
import '../providers/admin_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/highlight_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}



class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  // Mock Dark Mode state

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
        title: const Text(''),
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // Role Mode Switch (Admin only)
          if (authProvider.canSwitchRoles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    authProvider.isInUserMode ? 'User Mode' : 'Admin Mode',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: !authProvider.isInUserMode,
                    onChanged: (isAdmin) {
                      if (isAdmin) {
                        _switchToAdminMode(context, authProvider);
                      } else {
                        _showSwitchToUserDialog(context, authProvider);
                      }
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.blue,
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
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
            icon: const Icon(Icons.logout),
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
                   Colors.black.withOpacity(0.3),
                   Colors.black.withOpacity(0.5),
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white.withOpacity(0.1), // Semi-transparent nav bar
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.black,
        elevation: 0,
        type: BottomNavigationBarType.fixed, // Ensure items are visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
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
    // Removed unused user variable
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    final stats = adminProvider.dashboardStats;
    final totalUsers = stats?['total_users']?.toString() ?? '...';
    final activeUsers = stats?['active_users']?.toString() ?? '...';
    final pendingUsers = ((stats?['total_users'] ?? 0) - (stats?['verified_users'] ?? 0)).toString();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 16, // Add safe area + toolbar height
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            'Admin Dashboard',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

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
                    Expanded(child: _buildStatusCard('Total Users', totalUsers, Icons.people, Colors.blue, cardColor, textColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusCard('Active Now', activeUsers, Icons.wifi, Colors.green, cardColor, textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatusCard('Pending', pendingUsers, Icons.pending_actions, Colors.orange, cardColor, textColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusCard('Server', 'Online', Icons.dns, Colors.purple, cardColor, textColor)),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 1),

          // Quick Actions
          Text(
            'Quick Actions',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildActionCard(context, icon: Icons.notifications, title: 'Send Notification', color: Colors.orangeAccent, cardColor: cardColor, textColor: textColor, onTap: () => _showCreateNotificationDialog(context)),
              _buildActionCard(context, icon: Icons.video_library, title: 'Manage Highlights', color: Colors.deepPurple, cardColor: cardColor, textColor: textColor, onTap: () => _showUploadHighlightOptions(context)),
              _buildActionCard(context, icon: Icons.people, title: 'Manage Users', color: Colors.blue, cardColor: cardColor, textColor: textColor, onTap: () => Navigator.pushNamed(context, '/user-management')),
              _buildActionCard(context, icon: Icons.groups, title: 'Manage Teams', color: Colors.redAccent, cardColor: cardColor, textColor: textColor, onTap: () => Navigator.pushNamed(context, '/teams')),
              _buildActionCard(context, icon: Icons.event, title: 'Events', color: Colors.teal, cardColor: cardColor, textColor: textColor, onTap: () => Navigator.pushNamed(context, '/calendar')),
              _buildActionCard(context, icon: Icons.analytics, title: 'Analytics', color: Colors.green, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.admin_panel_settings, title: 'Roles & Perms', color: Colors.indigo, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.history, title: 'Audit Logs', color: Colors.brown, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.download, title: 'Export Data', color: Colors.deepOrange, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.report, title: 'Reports', color: Colors.purple, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.settings, title: 'Settings', color: Colors.grey, cardColor: cardColor, textColor: textColor, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              }),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color iconColor, Color cardColor, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Always white on glass
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70, // Always light on glass
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
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: color),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
                        await Provider.of<NotificationProvider>(context, listen: false)
                            .sendNotification(titleController.text, contentController.text);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification sent successfully!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send notification: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: const Text('Push'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon!')),
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
