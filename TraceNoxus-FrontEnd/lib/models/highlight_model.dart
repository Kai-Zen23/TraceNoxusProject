class HighlightModel {
  final int id;
  final String title;
  final String? videoFile;
  final String? videoUrl; // New
  final String? thumbnail;
  final String category;
  final String uploadedAt;
  final String? uploadedByUsername;

  HighlightModel({
    required this.id,
    required this.title,
    this.videoFile,
    this.videoUrl,
    this.thumbnail,
    required this.category,
    required this.uploadedAt,
    this.uploadedByUsername,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'],
      title: json['title'],
      videoFile: json['video_file'],
      videoUrl: json['video_url'],
      thumbnail: json['thumbnail'],
      category: json['category'],
      uploadedAt: json['uploaded_at'],
      uploadedByUsername: json['uploaded_by_username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_file': videoFile,
      'video_url': videoUrl,
      'thumbnail': thumbnail,
      'category': category,
      'uploaded_at': uploadedAt,
      'uploaded_by_username': uploadedByUsername,
    };
  }
}
