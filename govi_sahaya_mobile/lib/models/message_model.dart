class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImageUrl;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final int likes;
  final int comments;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImageUrl,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.likes,
    required this.comments,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? 'User',
      senderImageUrl: json['sender_image_url'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_image_url': senderImageUrl,
      'text': text,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
    };
  }
}
