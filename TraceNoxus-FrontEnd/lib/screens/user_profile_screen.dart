import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? _imageFile;
  bool isEditing = false;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController ageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
    final user = Provider.of<UserProvider>(context, listen: false).user;
    nameController = TextEditingController(text: user?.name ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    ageController = TextEditingController(text: user?.age?.toString() ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Widget _buildProfileCard(userProvider) {
    final user = userProvider.user;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (user?.profileImageUrl.isNotEmpty == true
                        ? NetworkImage(user!.profileImageUrl)
                        : null) as ImageProvider?,
                child: (user == null || (user.profileImageUrl.isEmpty && _imageFile == null))
                    ? const Icon(Icons.person, size: 48, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isEditing ? _pickImage : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.camera_alt, size: 20, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isEditing
              ? TextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Name',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )
              : Text(
                  user?.name ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
          const SizedBox(height: 4),
          isEditing
              ? TextField(
                  controller: emailController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                )
              : Text(
                  user?.email ?? '',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
          const SizedBox(height: 16),
          isEditing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await userProvider.updateUserProfile(
                          name: nameController.text,
                          age: int.tryParse(ageController.text),
                          profileImageFile: _imageFile,
                        );
                        setState(() {
                          isEditing = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                          nameController.text = user?.name ?? '';
                          emailController.text = user?.email ?? '';
                          _imageFile = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Edit Profile'),
                ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, userProvider) {
    return Column(
      children: [
        _menuTile(Icons.favorite_border, 'Favourites', onTap: () {}),
        _menuTile(Icons.download_outlined, 'Downloads', onTap: () {}),
        const Divider(),
        _menuTile(Icons.language, 'Language', onTap: () {}),
        _menuTile(Icons.location_on_outlined, 'Location', onTap: () {}),
        _menuTile(Icons.display_settings_outlined, 'Display', onTap: () {}),
        _menuTile(Icons.rss_feed, 'Feed preference', onTap: () {}),
        _menuTile(Icons.credit_card, 'Subscription', onTap: () {}),
        const Divider(),
        _menuTile(Icons.delete_outline, 'Clear Cache', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared!')));
        }),
        _menuTile(Icons.history, 'Clear history', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared!')));
        }),
        _menuTile(Icons.logout, 'Log Out', iconColor: Colors.red, onTap: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title, {VoidCallback? onTap, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(title, style: TextStyle(color: iconColor ?? Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      minLeadingWidth: 32,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildProfileCard(userProvider),
                _buildMenuList(context, userProvider),
              ],
            ),
    );
  }
} 