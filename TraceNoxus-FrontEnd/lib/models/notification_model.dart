class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? recipient;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.recipient,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'],
      recipient: json['recipient'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'recipient': recipient,
    };
  }
}
