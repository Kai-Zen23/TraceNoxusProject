import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'team_chat_screen.dart';

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

  void _selectTeam(BuildContext context, TeamChatConfig team) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _selectedTeamId = team.id;
    });

    if (!team.hasAccess(auth.currentUser)) {
      final roleHint =
          team.allowedRoles.isEmpty ? 'team members' : team.allowedRoles.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $roleHint can enter ${team.name} chat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeamChatScreen(config: team)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = _TeamsSpec.fromWidth(MediaQuery.of(context).size.width);

    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Layer - same as login_screen
          Positioned.fill(
            child: Image.asset(
              'assets/image/Background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load - use gradient similar to image description
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A2F4A),
                        const Color(0xFF2B4267),
                        const Color(0xFF1A3A5A),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Overlay for better text readability - lighter overlay to show background
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
                      // Back Button
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF88AEC9),
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      // Title
                      Text(
                        'Teams',
                        style: TextStyle(
                          color: const Color(0xFF88AEC9),
                          fontSize: spec.headerFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      // Users/Group Icon
                      IconButton(
                        icon: const Icon(
                          Icons.people_outline,
                          color: Color(0xFF88AEC9),
                          size: 28,
                        ),
                        onPressed: () {
                          // TODO: Show team members or group info
                        },
                      ),
                    ],
                  ),
                ),
                // Teams List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: spec.horizontalPadding,
                      vertical: spec.teamItemSpacing,
                    ),
                    itemCount: teamChatConfigs.length,
                    itemBuilder: (context, index) {
                      final team = teamChatConfigs[index];
                      final isSelected = _selectedTeamId == team.id;
                      final isLocked = !team.hasAccess(auth.currentUser);
                      return _TeamListItem(
                        team: team,
                        spec: spec,
                        isSelected: isSelected,
                        isLocked: isLocked,
                        onTap: () => _selectTeam(context, team),
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

// Team List Item Widget
class _TeamListItem extends StatelessWidget {
  final TeamChatConfig team;
  final _TeamsSpec spec;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _TeamListItem({
    required this.team,
    required this.spec,
    required this.isSelected,
    required this.onTap,
    required this.isLocked,
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
                ? Border.all(
                    color: const Color(0xFF88AEC9).withOpacity(0.5),
                    width: 2,
                  )
                : Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
          ),
          child: Row(
            children: [
              // Game Logo
              SizedBox(
                width: spec.teamLogoSize,
                height: spec.teamLogoSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: team.logoAsset != null
                      ? Image.asset(
                          team.logoAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _LogoFallback(team: team, spec: spec),
                        )
                      : _LogoFallback(team: team, spec: spec),
                ),
              ),
              const SizedBox(width: 16),
              // Game Name
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
              // Selection Indicator
              Icon(
                isLocked ? Icons.lock_outline : Icons.chat_bubble_outline,
                color: isLocked ? Colors.white54 : const Color(0xFF88AEC9),
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
  const _LogoFallback({required this.team, required this.spec});

  final TeamChatConfig team;
  final _TeamsSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: team.accentColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          team.name[0],
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
