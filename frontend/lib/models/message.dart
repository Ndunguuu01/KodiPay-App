class Message {
  final int? id;
  final int senderId;
  final int? receiverId;
  final int? groupId;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  final String? type; // 'text' or 'image'
  final String? senderName;

  Message({
    this.id,
    required this.senderId,
    this.receiverId,
    this.groupId,
    required this.content,
    this.isRead = false,
    this.createdAt,
    this.senderName,
    this.type,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: int.parse(json['sender_id'].toString()),
      receiverId: json['receiver_id'] != null ? int.tryParse(json['receiver_id'].toString()) : null,
      groupId: json['group_id'] != null ? int.tryParse(json['group_id'].toString()) : null,
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      senderName: json['sender'] != null ? json['sender']['name'] : null,
      type: json['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'group_id': groupId,
      'content': content,
      'type': type,
    };
  }
}
