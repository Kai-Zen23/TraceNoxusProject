import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart'; // Import TeamProvider
import '../models/team_model.dart';
import 'team_chat_screen.dart';
import 'team_detail_screen.dart';
import 'create_team_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({Key? key}) : super(key: key);

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsSpec {
  final double topSpacing;
  final double headerHeight;
  final double headerFontSize;
  final double teamItemHeight;
  final double teamLogoSize;
  final double teamNameFontSize;
  final double teamItemSpacing;
  final double horizontalPadding;

  const _TeamsSpec({
    required this.topSpacing,
    required this.headerHeight,
    required this.headerFontSize,
    required this.teamItemHeight,
    required this.teamLogoSize,
    required this.teamNameFontSize,
    required this.teamItemSpacing,
    required this.horizontalPadding,
  });

  factory _TeamsSpec.fromWidth(double width) {
    final topSpacing = _clampDouble(width * 0.08, 40, 80);
    final headerHeight = _clampDouble(width * 0.12, 60, 100);
    final headerFontSize = _clampDouble(width * 0.06, 24, 36);
    final teamItemHeight = _clampDouble(width * 0.15, 70, 100);
    final teamLogoSize = _clampDouble(width * 0.12, 50, 80);
    final teamNameFontSize = _clampDouble(width * 0.045, 18, 24);
    final teamItemSpacing = _clampDouble(width * 0.03, 12, 20);
    final horizontalPadding = _clampDouble(width * 0.06, 20, 40);

    return _TeamsSpec(
      topSpacing: topSpacing,
      headerHeight: headerHeight,
      headerFontSize: headerFontSize,
      teamItemHeight: teamItemHeight,
      teamLogoSize: teamLogoSize,
      teamNameFontSize: teamNameFontSize,
      teamItemSpacing: teamItemSpacing,
      horizontalPadding: horizontalPadding,
    );
  }
}

double _clampDouble(double value, double min, double max) {
  return math.min(math.max(value, min), max);
}

class _TeamsScreenState extends State<TeamsScreen> {
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchTeams();
    });
  }

  // Helper to map backend Team to TeamChatConfig for styling
  TeamChatConfig _mapToConfig(Team team) {
    // Try to find a matching predefined config by name substring
    final nameLower = team.name.toLowerCase();
    try {
      final preset = teamChatConfigs.firstWhere(
        (c) => nameLower.contains(c.name.toLowerCase()) || c.name.toLowerCase().contains(nameLower),
      );
      return TeamChatConfig(
        id: team.id.toString(), // Use backend ID
        name: team.name, // Use backend Name
        channelId: 'team_${team.id}', // Unique channel ID for THIS specific team
        backgroundAsset: preset.backgroundAsset,
        accentColor: preset.accentColor,
        logoAsset: preset.logoAsset,
        allowedRoles: [], // Access handled by backend
        bypassAccess: true,
      );
    } catch (e) {
      // Default fallback if no preset match
      return TeamChatConfig(
        id: team.id.toString(),
        name: team.name,
        channelId: 'team_${team.id}', // Unique channel ID
        backgroundAsset: 'assets/image/Background.png',
        accentColor: Colors.blueGrey,
        logoAsset: null, // Will use fallback letter
        allowedRoles: [],
        bypassAccess: true,
      );
    }
  }

  void _selectTeam(BuildContext context, Team team) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _selectedTeamId = team.id.toString();
    });

    if (auth.isAdmin) {
       // Navigate to Team Detail for Admin
       Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)));
    } else {
       // Navigate to Chat for Users
       final config = _mapToConfig(team);
       Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TeamChatScreen(config: config)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _TeamsSpec.fromWidth(MediaQuery.of(context).size.width);
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/image/Background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A2F4A), Color(0xFF2B4267), Color(0xFF1A3A5A)],
                    ),
                  ),
                );
              },
            ),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          // Content Layer
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spec.horizontalPadding,
                    vertical: spec.topSpacing,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Color(0xFF88AEC9), size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Teams',
                        style: TextStyle(
                          color: const Color(0xFF88AEC9),
                          fontSize: spec.headerFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                       // Hide "Create" button if not admin
                       // We can enable this once CreateTeamScreen is ready
                       if (auth.isAdmin)
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF88AEC9), size: 28),
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTeamScreen()));
                          },
                        )
                       else
                        const SizedBox(width: 28), // Placeholder to center title
                    ],
                  ),
                ),
                // Teams List
                Expanded(
                  child: Consumer<TeamProvider>(
                    builder: (context, teamProvider, child) {
                      if (teamProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF88AEC9)));
                      }
                      
                      final teams = teamProvider.teams;
                      
                      if (teams.isEmpty) {
                        return Center(
                           child: Text(
                             auth.isAdmin 
                               ? 'No teams yet.\nCreate one via Admin Panel.' 
                               : 'You have not been assigned to a team yet.',
                             textAlign: TextAlign.center,
                             style: const TextStyle(color: Colors.white70),
                           )
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: spec.horizontalPadding,
                          vertical: spec.teamItemSpacing,
                        ),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          final isSelected = _selectedTeamId == team.id.toString();
                          // Map to config just for display assets
                          final config = _mapToConfig(team);
                          
                          return _TeamListItem(
                            team: team,
                            config: config,
                            spec: spec,
                            isSelected: isSelected,
                            onTap: () => _selectTeam(context, team),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamListItem extends StatelessWidget {
  final Team team;
  final TeamChatConfig config;
  final _TeamsSpec spec;
  final bool isSelected;
  final VoidCallback onTap;

  const _TeamListItem({
    required this.team,
    required this.config,
    required this.spec,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: spec.teamItemSpacing),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: spec.teamItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: const Color(0xFF88AEC9).withOpacity(0.5), width: 2)
                : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: spec.teamLogoSize,
                height: spec.teamLogoSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: config.logoAsset != null
                      ? Image.asset(
                          config.logoAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _LogoFallback(name: team.name, color: config.accentColor, spec: spec),
                        )
                      : _LogoFallback(name: team.name, color: config.accentColor, spec: spec),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  team.name,
                  style: TextStyle(
                    color: const Color(0xFF88AEC9),
                    fontSize: spec.teamNameFontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF88AEC9),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.name, required this.color, required this.spec});

  final String name;
  final Color color;
  final _TeamsSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: spec.teamLogoSize * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Duplicate TeamChatConfig removed to use the one from team_chat_screen.dart
