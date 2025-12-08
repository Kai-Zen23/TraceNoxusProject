import '../core/constants/app_constants.dart';

class MessageModel {
  final int id;
  final int sender;
  final int? receiver;
  final String content;
  final DateTime timestamp;
  final String? senderName;
  final String? senderProfileImage;

  MessageModel({
    required this.id, 
    required this.sender, 
    this.receiver, 
    required this.content, 
    required this.timestamp, 
    this.senderName,
    this.senderProfileImage,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String? rawProfileImage = json['sender_profile_image'] as String?;
    if (rawProfileImage != null) {
      if (rawProfileImage.startsWith('file://')) {
        rawProfileImage = rawProfileImage.replaceFirst('file://', '');
      }
      if (!rawProfileImage.startsWith('http')) {
        rawProfileImage = '${AppConstants.baseUrl}$rawProfileImage';
      }
    }

    return MessageModel(
      id: json['id'] as int,
      sender: json['sender'] as int,
      receiver: json['receiver'] == null ? null : json['receiver'] as int,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      senderName: (json['sender_username'] ?? json['sender_name']) as String?,
      senderProfileImage: rawProfileImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (receiver != null) 'receiver': receiver,
      'content': content,
    };
  }
}