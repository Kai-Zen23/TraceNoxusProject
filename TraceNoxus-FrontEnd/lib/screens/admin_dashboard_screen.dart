import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/user_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart'; // Import SettingsScreen
import '../providers/admin_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

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
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFD3E3EA),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF2B4267),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminHomeTab(isDarkMode: _isDarkMode, onNavigate: (index) => setState(() => _selectedIndex = index)),
          const UserListScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: _isDarkMode ? Colors.blueAccent : const Color(0xFF2B4267),
        unselectedItemColor: _isDarkMode ? Colors.grey : Colors.grey,
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
    final user = authProvider.currentUser;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    final stats = adminProvider.dashboardStats;
    final totalUsers = stats?['total_users']?.toString() ?? '...';
    final activeUsers = stats?['active_users']?.toString() ?? '...';
    final pendingUsers = ((stats?['total_users'] ?? 0) - (stats?['verified_users'] ?? 0)).toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search users, events, reports...',
              hintStyle: TextStyle(color: widget.isDarkMode ? Colors.grey : Colors.grey[600]),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 24),

          // System Status Snapshot
          Text(
            'System Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
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
          const SizedBox(height: 24),

          // Notifications Panel
          Text(
            'Announcement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildNotificationItem('New user registration: @john_doe', '2 mins ago', Icons.person_add, Colors.blue, textColor),
                const Divider(height: 1),
                _buildNotificationItem('System warning: High CPU usage', '1 hour ago', Icons.warning, Colors.amber, textColor),
                const Divider(height: 1),
                _buildNotificationItem('Report flagged: Post #402', '3 hours ago', Icons.flag, Colors.red, textColor),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildActionCard(context, icon: Icons.notifications, title: 'Send Notification', color: Colors.orangeAccent, cardColor: cardColor, textColor: textColor, onTap: () => _showCreateNotificationDialog(context)),
              _buildActionCard(context, icon: Icons.people, title: 'Manage Users', color: Colors.blue, cardColor: cardColor, textColor: textColor, onTap: () => widget.onNavigate(1)),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color iconColor, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String message, String time, IconData icon, Color iconColor, Color textColor) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        message,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: Text(
        time,
        style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5)),
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
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
}
