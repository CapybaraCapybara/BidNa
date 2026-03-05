import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // สร้าง roomId จาก UID สองคน
  String getRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join("_");
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