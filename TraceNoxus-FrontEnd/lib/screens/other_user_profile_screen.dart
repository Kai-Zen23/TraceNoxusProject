import 'package:flutter/material.dart';

class OtherUserProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const OtherUserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Extract data with fallbacks
    final username = (user['username'] ?? 'User').toString();
    final name = (user['name'] ?? user['first_name'] ?? username).toString();
    final role = (user['role'] ?? 'User').toString();
    final profileImage = user['profile_image'];
    
    // Parse complex fields
    final gamesPlayed = user['games_played'];
    final competitiveLevel = user['competitive_level']?.toString() ?? 'Not set';
    final preferredRoles = user['preferred_roles']?.toString() ?? 'Not set';

    String displayGames = 'None';
    if (gamesPlayed is String && gamesPlayed.isNotEmpty) {
      displayGames = gamesPlayed;
    } else if (gamesPlayed is List && gamesPlayed.isNotEmpty) {
       displayGames = gamesPlayed.join(', ');
    }

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
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.blue),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Optional: Add actions like "Add Friend" here if needed
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Profile Image
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: profileImage != null && profileImage.toString().isNotEmpty
                                ? NetworkImage(profileImage)
                                : null,
                            child: (profileImage == null || profileImage.toString().isEmpty)
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Name and Username
                        Text(
                          name.isNotEmpty ? name : username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@$username',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                             color: Colors.blue.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.blue.withOpacity(0.5))
                          ),
                          child: Text(
                             role.toUpperCase(),
                             style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 32),
                        
                        // Games Played
                        _buildSectionTitle('Games Played:'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                displayGames,
                                icon: Icons.sports_esports,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Competitive Level and Preferred Roles
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Competitive Level:'),
                                  const SizedBox(height: 8),
                                  _buildInfoCard(
                                    competitiveLevel,
                                    icon: Icons.emoji_events,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Preferred Roles:'),
                                  const SizedBox(height: 8),
                                  _buildInfoCard(
                                    preferredRoles,
                                    icon: Icons.person_outline,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInfoCard(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(height: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
