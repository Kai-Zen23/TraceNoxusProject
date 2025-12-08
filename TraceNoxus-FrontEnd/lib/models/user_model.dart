import '../core/constants/app_constants.dart';

class UserModel {
  final int id;
  final String email;
  final String username;
  final String role; // 'admin' or 'user'
  final String? firstName;
  final String? lastName;
  final bool isVerified;
  final bool? isStaff; // Added for correct admin check
  final DateTime? dateJoined;
  final DateTime? lastLogin;
  // Legacy fields for backward compatibility
  final String? name;
  final String? profileImageUrl;
  final int? age;
  final String? gamesPlayed;
  final String? competitiveLevel;
  final String? preferredRoles;
  final String? gamespadPlayed;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.firstName,
    this.lastName,
    required this.isVerified,
    this.isStaff,
    this.dateJoined,
    this.lastLogin,
    this.name,
    this.profileImageUrl,
    this.age,
    this.gamesPlayed,
    this.competitiveLevel,
    this.preferredRoles,
    this.gamespadPlayed,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? rawProfileImage = (json['profile_image'] as String?) ?? 
                             (json['profile_image_url'] as String?) ?? 
                             (json['profileImage'] as String?);

    if (rawProfileImage != null) {
      if (rawProfileImage.startsWith('file://')) {
        rawProfileImage = rawProfileImage.replaceFirst('file://', '');
      }
      if (!rawProfileImage.startsWith('http')) {
        rawProfileImage = '${AppConstants.baseUrl}$rawProfileImage';
      }
    }

    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String? ?? json['email'] as String,
      role: json['role'] as String? ?? 'user',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isStaff: json['is_staff'] as bool?,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'] as String)
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      name: json['name'] as String? ?? json['username'] as String? ?? json['first_name'] as String?,
      profileImageUrl: rawProfileImage,
      age: json['age'] as int?,
      gamesPlayed: json['games_played'] as String?,
      competitiveLevel: json['competitive_level'] as String?,
      preferredRoles: json['preferred_roles'] as String?,
      gamespadPlayed: json['Game_genre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'is_verified': isVerified,
      'is_staff': isStaff,
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'profile_image': profileImageUrl,
      'games_played': gamesPlayed,
      'competitive_level': competitiveLevel,
      'preferred_roles': preferredRoles,
      'Game_genre': gamespadPlayed,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => role.toLowerCase() == 'user';
}