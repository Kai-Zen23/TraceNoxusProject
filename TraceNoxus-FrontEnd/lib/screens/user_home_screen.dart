import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openFriends() => Navigator.pushNamed(context, '/friends');
  void _openMessages() => Navigator.pushNamed(context, '/messages');
  void _openCalendar() => Navigator.pushNamed(context, '/calendar');
  void _openNotifications() => Navigator.pushNamed(context, '/notifications');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final name = _nameController.text.trim();
    await userProvider.updateUserProfile(
      name: name.isEmpty ? (userProvider.user?.name ?? userProvider.user?.username ?? '') : name,
      profileImageFile: _pickedImage,
    );
    await userProvider.loadUserData();
    if (mounted) {
      setState(() => _pickedImage = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    if (user != null && _nameController.text.isEmpty) {
      _nameController.text = user.name ?? user.username;
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF2B4267),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 54,
                backgroundColor: Colors.white,
                backgroundImage: _pickedImage != null
                    ? FileImage(File(_pickedImage!.path))
                    : (user != null && user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                        ? NetworkImage(user.profileImageUrl!)
                        : null as ImageProvider?,
                child: (_pickedImage == null && (user == null || user.profileImageUrl == null || user.profileImageUrl!.isEmpty))
                    ? const Icon(Icons.person, size: 54, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? user?.username ?? 'User',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Edit name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: userProvider.isLoading ? null : _pickImage,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9CB3C9), foregroundColor: const Color(0xFF2B4267)),
                        child: const Text('Change Photo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: userProvider.isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9CB3C9), foregroundColor: const Color(0xFF2B4267)),
                        child: userProvider.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  child: const Text('Logout'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
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
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'TRACE NOXUS',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Welcome, ${user?.name ?? user?.username ?? 'User'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(colors: [Color(0xFF4D87B6), Color(0xFF2E5E88)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/image/placeholder.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_outlined, color: Colors.white, size: 64)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Highlights',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    height: 72,
                    decoration: BoxDecoration(color: const Color(0xFF6EA5CE).withOpacity(0.85), borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(icon: const Icon(Icons.group, color: Colors.white), onPressed: _openFriends),
                        IconButton(icon: const Icon(Icons.chat_bubble, color: Colors.white), onPressed: _openMessages),
                        IconButton(icon: const Icon(Icons.calendar_month, color: Colors.white), onPressed: _openCalendar),
                        IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: _openNotifications),
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
