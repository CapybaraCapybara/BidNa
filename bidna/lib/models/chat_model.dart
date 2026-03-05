import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final List<String> users;
  final String lastMessage;
  final DateTime? lastTimestamp;

  ChatRoomModel({
    required this.roomId,
    required this.users,
    required this.lastMessage,
    this.lastTimestamp,
  });

  factory ChatRoomModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      roomId: doc.id,
      users: List<String>.from(d['users'] ?? []),
      lastMessage: d['lastMessage'] ?? '',
      lastTimestamp: (d['lastTimestamp'] as Timestamp?)?.toDate(),
    );
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? image;
  final DateTime? timestamp;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.image,
    this.timestamp,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: doc.id,
      senderId: d['senderId'] ?? '',
      receiverId: d['receiverId'] ?? '',
      text: d['text'],
      image: d['image'],
      timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}