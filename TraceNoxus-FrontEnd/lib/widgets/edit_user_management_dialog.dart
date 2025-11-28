import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_management_provider.dart';
import '../models/user_management_model.dart';
import '../models/game_enum.dart';

class EditUserManagementDialog extends StatefulWidget {
  final UserManagementModel user;

  const EditUserManagementDialog({super.key, required this.user});

  @override
  State<EditUserManagementDialog> createState() => _EditUserManagementDialogState();
}

class _EditUserManagementDialogState extends State<EditUserManagementDialog> {
  late String _selectedRole;
  late List<GamePlayed> _selectedGames;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _selectedGames = List.from(widget.user.gamesPlayed);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Role Credentials', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Game Played Checkboxes
            const Text('Game Played', style: TextStyle(fontWeight: FontWeight.bold)),
            ...GamePlayed.values.map((game) => CheckboxListTile(
              title: Text(game.displayName),
              value: _selectedGames.contains(game),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGames.add(game);
                  } else {
                    _selectedGames.remove(game);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            )),

            const SizedBox(height: 16),

            // User Role Radio Buttons
            const Text('User Role', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio<String>(
                  value: 'user',
                  groupValue: _selectedRole,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const Text('User'),
                Radio<String>(
                  value: 'admin',
                  groupValue: _selectedRole,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const Text('Admin'),
              ],
            ),

            const SizedBox(height: 16),

            // Username Field
            const Text('Username *', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _usernameController),

            const SizedBox(height: 16),

            // Email Field
            const Text('Email Address *', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _emailController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final updatedUser = UserManagementModel(
      id: widget.user.id,
      username: _usernameController.text,
      email: _emailController.text,
      role: _selectedRole,
      gamesPlayed: _selectedGames,
    );

    context.read<UserManagementProvider>().updateUser(widget.user.id, updatedUser);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}