class UserModel {
  final String name;
  final String email;
  final String profileImageUrl;
  final int? age;

  UserModel({
    required this.name,
    required this.email,
    required this.profileImageUrl,
    this.age
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    profileImageUrl: json['profile_image_url'] ?? '',
    age: json['age'],
  );
}
} 