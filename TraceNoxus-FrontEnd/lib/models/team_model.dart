import 'user_management_model.dart';

class Team {
  final int id;
  final String name;
  final String description;
  final String? logo;
  final int createdBy;
  final String createdByUsername;
  final List<int> members;
  final List<UserManagementModel> membersDetails;
  final String createdAt;

  Team({
    required this.id,
    required this.name,
    required this.description,
    this.logo,
    required this.createdBy,
    required this.createdByUsername,
    required this.members,
    required this.membersDetails,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      logo: json['logo'],
      createdBy: json['created_by'],
      createdByUsername: json['created_by_username'] ?? 'Unknown',
      members: List<int>.from(json['members'] ?? []),
      membersDetails: (json['members_details'] as List<dynamic>?)
              ?.map((e) => UserManagementModel.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'created_by': createdBy,
      'members': members,
    };
  }
}
