import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:bidna/models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // สร้าง roomId จาก UID สองคน
  String getRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  // B4: ย้าย image processing ออกจาก UI มาไว้ใน Service
  Future<String> processImageToBase64(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return '';
    final resized = img.copyResize(decoded, width: 500);
    final compressed = img.encodeJpg(resized, quality: 60);
    return base64Encode(compressed);
  }

  // B4: ย้าย sender name fetch ออกจาก UI มาไว้ใน Service
  Future<String> getSenderName(String uid) async {
    final doc = await _db.collection('Users').doc(uid).get();
    if (!doc.exists) return 'Someone';
    return (doc.data() as Map<String, dynamic>)['displayName'] ?? 'Someone';
  }

  // B4: ย้าย Stream query ออกจาก UI มาไว้ใน Service
  Stream<List<ChatRoomModel>> getUserChatRoomsStream(String uid) {
    return _db
        .collection('ChatRooms')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final rooms =
          snapshot.docs.map((doc) => ChatRoomModel.fromDoc(doc)).toList();

      // B4: ย้าย sort logic ออกจาก UI มาไว้ใน Service
      rooms.sort((a, b) {
        if (a.lastTimestamp == null && b.lastTimestamp == null) return 0;
        if (a.lastTimestamp == null) return 1;
        if (b.lastTimestamp == null) return -1;
        return b.lastTimestamp!.compareTo(a.lastTimestamp!);
      });

      return rooms;
    });
  }

  // ส่งข้อความ
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String receiverId,
    required String senderName,
    String? text,
    String? imageBase64,
  }) async {
    final msgData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text?.trim(),
      'image': imageBase64,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // บันทึกข้อความ
    await _db.collection('ChatRooms').doc(roomId).collection('messages').add(msgData);

    // อัปเดตห้องแชท
    await _db.collection('ChatRooms').doc(roomId).set({
      'users': [senderId, receiverId],
      'lastMessage': imageBase64 != null ? "📷 Sent an image" : text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ส่งแจ้งเตือนแชทให้ผู้รับ
    await _db.collection('Users').doc(receiverId).collection('notifications').add({
      'title': 'New Message',
      'message': '$senderName sent you a message.',
      'isRead': false,
      'type': 'CHAT',
      'peerId': senderId,
      'peerName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}