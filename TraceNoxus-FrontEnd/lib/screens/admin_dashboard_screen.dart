import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/user_list_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart'; // Import SettingsScreen
import '../providers/admin_provider.dart';
import '../providers/notification_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false; // Mock Dark Mode state

  final List<Widget> _screens = [
    const UserListScreen(),
    const UserProfileScreen(),
  ];

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
      body: _selectedIndex == 0
          ? AdminHomeTab(isDarkMode: _isDarkMode, onNavigate: (index) => setState(() => _selectedIndex = index))
          : _screens[_selectedIndex - 1],
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
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (notificationProvider.error != null) {
                return Text('Error: ${notificationProvider.error}', style: const TextStyle(color: Colors.red));
              }
              if (notificationProvider.notifications.isEmpty) {
                return Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('No recent notifications', style: TextStyle(color: textColor))),
                  ),
                );
              }

              // Show top 3 notifications
              final recentNotifications = notificationProvider.notifications.take(3).toList();

              return Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: recentNotifications.asMap().entries.map((entry) {
                    final index = entry.key;
                    final notification = entry.value;
                    return Column(
                      children: [
                        _buildNotificationItem(
                          notification.title,
                          _formatTime(notification.createdAt),
                          Icons.notifications,
                          Colors.blue,
                          textColor,
                        ),
                        if (index < recentNotifications.length - 1) const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
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
              _buildActionCard(context, icon: Icons.people, title: 'Manage Users', color: Colors.blue, cardColor: cardColor, textColor: textColor, onTap: () => Navigator.pushNamed(context, '/user-management')),
              _buildActionCard(context, icon: Icons.event, title: 'Events', color: Colors.teal, cardColor: cardColor, textColor: textColor, onTap: () => Navigator.pushNamed(context, '/calendar')),
              _buildActionCard(context, icon: Icons.notifications, title: 'Notifications', color: Colors.orange, cardColor: cardColor, textColor: textColor, onTap: () => Navigator.pushNamed(context, '/notifications')),
              _buildActionCard(context, icon: Icons.admin_panel_settings, title: 'Roles & Perms', color: Colors.indigo, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.history, title: 'Audit Logs', color: Colors.brown, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.download, title: 'Export Data', color: Colors.deepOrange, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
              _buildActionCard(context, icon: Icons.analytics, title: 'Analytics', color: Colors.green, cardColor: cardColor, textColor: textColor, onTap: () => _showComingSoon(context)),
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon!')),
    );
  }
}