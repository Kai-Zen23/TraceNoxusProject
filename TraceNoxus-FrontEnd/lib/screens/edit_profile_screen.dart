import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'settings_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _gamesController;

  late TextEditingController _levelController;
  late TextEditingController _rolesController;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? user?.username);
    _gamesController = TextEditingController(text: user?.gamesPlayed);
    _levelController = TextEditingController(text: user?.competitiveLevel);
    _rolesController = TextEditingController(text: user?.preferredRoles);

  }

  @override
  void dispose() {
    _nameController.dispose();
    _gamesController.dispose();
    _levelController.dispose();
    _rolesController.dispose();

    super.dispose();
  }

  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    
    setState(() => _isPickingImage = true);
    
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      // If the error is 'already_active', we can mostly ignore it or show a toast
      if (e is! Exception || !e.toString().contains('already_active')) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to pick image')),
            );
         }
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await userProvider.updateUserProfile(
      name: _nameController.text.trim(),
      profileImageFile: _pickedImage,
      gamesPlayed: _gamesController.text.trim(),
      competitiveLevel: _levelController.text.trim(),
      preferredRoles: _rolesController.text.trim(),

    );

    if (!mounted) return;

    if (userProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProvider.error!), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    }
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
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F172A)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.blue),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Profile Image with Edit Icon
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: _pickedImage != null
                                      ? FileImage(File(_pickedImage!.path))
                                      : (user?.profileImageUrl != null
                                      ? NetworkImage(user!.profileImageUrl!)
                                      : null as ImageProvider?),
                                  child: (_pickedImage == null && user?.profileImageUrl == null)
                                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                              if (user?.profileImageUrl != null || _pickedImage != null)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (_pickedImage != null) {
                                        setState(() => _pickedImage = null);
                                      } else {
                                        // Remove existing profile image
                                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                                        await userProvider.updateUserProfile(
                                          name: _nameController.text.trim(),
                                          removeProfileImage: true,
                                        );
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Profile picture removed')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name and Username
                          Text(
                            user?.name ?? user?.username ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '@${user?.username}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Save Changes Button
                          ElevatedButton.icon(
                            onPressed: userProvider.isLoading ? null : _saveProfile,
                            icon: userProvider.isLoading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save, size: 16),
                            label: Text(userProvider.isLoading ? 'Saving...' : 'Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form Fields
                          _buildTextField('Display Name', _nameController),
                          const SizedBox(height: 16),
                          _buildTextField('Games Played', _gamesController, icon: Icons.sports_esports),
                          const SizedBox(height: 16),
                          _buildTextField('Competitive Level', _levelController, icon: Icons.emoji_events),
                          const SizedBox(height: 16),
                          _buildTextField('Preferred Roles', _rolesController, icon: Icons.person_outline),
                          const SizedBox(height: 32),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
