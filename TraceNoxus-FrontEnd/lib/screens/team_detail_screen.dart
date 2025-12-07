import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team_model.dart';
import '../models/user_management_model.dart';
import '../models/game_enum.dart';
import '../providers/team_provider.dart';
import '../providers/user_management_provider.dart';
import 'team_chat_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  
  @override
  void initState() {
    super.initState();
    // Fetch fresh team data to ensure member list is up to date
    WidgetsBinding.instance.addPostFrameCallback((_) {
       context.read<TeamProvider>().refreshTeam(widget.team.id.toString());
       context.read<UserManagementProvider>().fetchUsers(); // Pre-fetch users for Add Member dialog
    });
  }

  Future<void> _removeMember(UserManagementModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Remove ${user.username} from ${widget.team.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Update user to have NO game played, which triggers removal from team
        final updatedUser = UserManagementModel(
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role,
          gamesPlayed: [], // Empty list = None
        );
        
        await context.read<UserManagementProvider>().updateUser(user.id, updatedUser);
        await context.read<TeamProvider>().refreshTeam(widget.team.id.toString());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member removed")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  Future<void> _confirmDeleteTeam(BuildContext context, Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete ${team.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<TeamProvider>().deleteTeam(team.id.toString());
        if (mounted) {
           Navigator.pop(context); // Go back to TeamsScreen
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showAddMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemberSheet(team: widget.team),
    );
  }

  void _joinChat(Team team) {
    // Map team to config (Logic duplicated from TeamsScreen to ensure consistency)
    final nameLower = team.name.toLowerCase();
    TeamChatConfig config;
    try {
      final preset = teamChatConfigs.firstWhere(
        (c) => nameLower.contains(c.name.toLowerCase()) || c.name.toLowerCase().contains(nameLower),
      );
      config = TeamChatConfig(
        id: team.id.toString(),
        name: team.name,
        channelId: 'team_${team.id}', // Consistent unique ID
        backgroundAsset: preset.backgroundAsset,
        accentColor: preset.accentColor,
        logoAsset: preset.logoAsset,
        allowedRoles: [],
        bypassAccess: true,
      );
    } catch (_) {
      config = TeamChatConfig(
        id: team.id.toString(),
        name: team.name,
        channelId: 'team_${team.id}',
        backgroundAsset: 'assets/image/Background.png',
        accentColor: Colors.blueGrey,
        allowedRoles: [],
        bypassAccess: true,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeamChatScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the team from provider to get updates
    final teamProvider = context.watch<TeamProvider>();
    // Find the updated team object in the list, or use the widget.team as fallback
    final currentTeam = teamProvider.teams.firstWhere(
      (t) => t.id == widget.team.id,
      orElse: () => widget.team,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTeam.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            tooltip: 'Join Team Chat',
            onPressed: () => _joinChat(currentTeam),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeleteTeam(context, currentTeam),
          ),
        ],
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(currentTeam.description),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("Created by: ${currentTeam.createdByUsername}", style: const TextStyle(color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Members",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentTeam.membersDetails.length,
              itemBuilder: (context, index) {
                final member = currentTeam.membersDetails[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(member.username[0].toUpperCase()),
                  ),
                  title: Text(member.username),
                  subtitle: Text(member.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeMember(member),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final Team team;
  const _AddMemberSheet({required this.team});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  String _searchQuery = "";

  Future<void> _addMember(UserManagementModel user) async {
    try {
      // Map team name to GamePlayed enum
      // We need to parse strict Enum value from team name string like "VALORANT Team" or "VALORANT"
      // The backend expects String in JSON but Frontend Model uses Enum list.
      // Let's assume the Team Name CONTAINS the game name.
      
      GamePlayed? targetGame;
      final teamNameUpper = widget.team.name.toUpperCase();
      
      if (teamNameUpper.contains("VALORANT")) targetGame = GamePlayed.valorant;
      else if (teamNameUpper.contains("MOBILE LEGENDS")) targetGame = GamePlayed.mobileLegends;
      else if (teamNameUpper.contains("LEAGUE OF LEGENDS")) targetGame = GamePlayed.leagueOfLegends;
      else if (teamNameUpper.contains("TEKKEN")) targetGame = GamePlayed.tekken8;
      
      if (targetGame == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot determine game from team name. Automatic assignment might fail.")));
          return;
      }

      final updatedUser = UserManagementModel(
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role,
          gamesPlayed: [targetGame],
      );

      await context.read<UserManagementProvider>().updateUser(user.id, updatedUser);
      await context.read<TeamProvider>().refreshTeam(widget.team.id.toString());
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${user.username} added to team")));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all users
    final allUsers = context.watch<UserManagementProvider>().users;
    // Filter out users already in the team
    final existingMemberIds = widget.team.membersDetails.map((m) => m.id).toSet();
    
    final availableUsers = allUsers.where((u) => !existingMemberIds.contains(u.id)).toList();
    
    // Apply search filter
    final filteredUsers = _searchQuery.isEmpty 
        ? availableUsers 
        : availableUsers.where((u) => u.username.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Text("Add Member", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: "Search users...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredUsers.isEmpty 
             ? const Center(child: Text("No users found"))
             : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user.username[0].toUpperCase())),
                  title: Text(user.username),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onPressed: () => _addMember(user),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
