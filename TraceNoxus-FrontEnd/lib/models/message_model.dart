// d:\Software Engineering Project\TraceNoxusProject\TraceNoxus-FrontEnd\lib\models\message_model.dart
class MessageModel {
  final int id;
  final int sender;
  final int? receiver;
  final String content;
  final DateTime timestamp;
  final String? senderName;

  MessageModel({required this.id, required this.sender, this.receiver, required this.content, required this.timestamp, this.senderName});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      sender: json['sender'] as int,
      receiver: json['receiver'] == null ? null : json['receiver'] as int,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      senderName: (json['sender_username'] ?? json['sender_name']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (receiver != null) 'receiver': receiver,
      'content': content,
    };
  }
}