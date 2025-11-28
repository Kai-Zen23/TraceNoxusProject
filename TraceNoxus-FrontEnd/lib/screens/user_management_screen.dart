import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_management_provider.dart';
import '../models/user_management_model.dart';
import '../models/game_enum.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserManagementModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = context.read<UserManagementProvider>().users;
  }

  void _filterUsers(String query) {
    final provider = context.read<UserManagementProvider>();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = provider.users;
      } else {
        _filteredUsers = provider.users.where((user) {
          return user.username.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              user.role.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<UserManagementProvider>().deleteUser(userId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted successfully')),
              );
              // Refresh filtered list
              _filterUsers(_searchController.text);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Changed to bottom sheet
  void _showEditDialog(UserManagementModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditUserDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Manage Users",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          /// BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/image/AdminBG.png",
              fit: BoxFit.cover,
            ),
          ),

          /// CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  /// SEARCH BAR
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: "Search users...",
                        border: InputBorder.none,
                      ),
                      onChanged: _filterUsers,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// TITLE
                  const Text(
                    "User List",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// GLASS TABLE
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Consumer<UserManagementProvider>(
                          builder: (context, provider, child) {
                            final users = _filteredUsers;

                            return Column(
                              children: [
                                /// HEADER
                                Container(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.white30)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Username",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Games Played",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "Role",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "Actions",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                /// USER LIST
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.white12)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                user.username,
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                user.gamesPlayedString,
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                user.role.toUpperCase(),
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Row(
                                                children: [
                                                  /// EDIT BUTTON
                                                  GestureDetector(
                                                    onTap: () => _showEditDialog(user),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.lightBlueAccent,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        "Edit",
                                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  /// DELETE BUTTON
                                                  GestureDetector(
                                                    onTap: () => _deleteUser(user.id),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.redAccent,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        "Delete",
                                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
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

// ✅ UPDATED: New bottom sheet design
class EditUserDialog extends StatefulWidget {
  final UserManagementModel user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late String _selectedRole;
  late List<String> _selectedGames;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  final List<String> _availableGames = [
    "VALORANT",
    "MOBILE LEGENDS",
    "LEAGUE OF LEGENDS",
    "TEKKEN 8"
  ];

  final List<String> _availableRoles = ["user", "admin"];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _selectedGames = widget.user.gamesPlayedString.split(' / ').toList();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
  }

  void _saveChanges() {
    final List<GamePlayed> selectedGameEnums = _selectedGames.map((game) {
      switch (game) {
        case 'VALORANT':
          return GamePlayed.valorant;
        case 'MOBILE LEGENDS':
          return GamePlayed.mobileLegends;
        case 'LEAGUE OF LEGENDS':
          return GamePlayed.leagueOfLegends;
        case 'TEKKEN 8':
          return GamePlayed.tekken8;
        default:
          return GamePlayed.valorant;
      }
    }).toList();

    final updatedUser = UserManagementModel(
      id: widget.user.id,
      username: _usernameController.text,
      email: _emailController.text,
      role: _selectedRole,
      gamesPlayed: selectedGameEnums,
    );

    context.read<UserManagementProvider>().updateUser(widget.user.id, updatedUser);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Updated: ${_usernameController.text}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25,
      ),
      decoration: BoxDecoration(
        color: Color(0xff77a9d6), // BLUE UI
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Center(
              child: Text(
                "Edit User",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 25),

            // Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            SizedBox(height: 15),

            // Email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            SizedBox(height: 15),

            // Role Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                underline: SizedBox(),
                items: _availableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRole = value!);
                },
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Games Played",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 10),

            Column(
              children: _availableGames.map((game) {
                return CheckboxListTile(
                  value: _selectedGames.contains(game),
                  activeColor: Colors.white,
                  checkColor: Colors.black,
                  title: Text(game, style: TextStyle(color: Colors.white)),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedGames.add(game);
                      } else {
                        _selectedGames.remove(game);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saveChanges,
                child: Text(
                  "SAVE CHANGES",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}