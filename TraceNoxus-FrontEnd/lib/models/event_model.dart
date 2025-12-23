class EventModel {
  final int id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final bool isReminderOn;
  final String? backgroundImage;
  final int? createdBy;
  final String? createdByUsername;
  final String? createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.isReminderOn,
    this.backgroundImage,
    this.createdBy,
    this.createdByUsername,
    this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      date: json['date'],
      time: json['time'],
      location: json['location'],
      isReminderOn: json['is_reminder_on'] ?? false,
      backgroundImage: json['background_image'],
      createdBy: json['created_by'],
      createdByUsername: json['created_by_username'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'is_reminder_on': isReminderOn,
      'background_image': backgroundImage,
      'created_by': createdBy,
      'created_by_username': createdByUsername,
      'created_at': createdAt,
    };
  }
}
