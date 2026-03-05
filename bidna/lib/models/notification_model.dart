import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String type; // OUTBID, WON, CHAT, SYSTEM
  final String? productId;
  final String? peerId;
  final String? peerName;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    this.productId,
    this.peerId,
    this.peerName,
    required this.createdAt,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: d['title'] ?? 'Notification',
      message: d['message'] ?? '',
      isRead: d['isRead'] ?? false,
      type: d['type'] ?? 'SYSTEM',
      productId: d['productId'],
      peerId: d['peerId'],
      peerName: d['peerName'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}