// 🔴 เพิ่ม Import สำหรับจัดการรูปภาพ
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:cloud_firestore/cloud_firestore.dart';
// 🔴 Import NotificationModel สำหรับใช้ใน getNotificationsStream
import 'package:bidna/models/notification_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUserData(String uid) {
    return _db.collection('Users').doc(uid).get();
  }

  // 2. ดึงข้อมูล User แบบ Real-time (Stream) สำหรับดักฟังดาว/รีวิว
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('Users').doc(uid).snapshots();
  }

  // ==========================================
  // 🟢 ส่วนที่เพิ่มใหม่สำหรับจัดการรูปโปรไฟล์ (ข้อ B4)
  // ==========================================

  // B4: ย้าย Logic การบีบอัดและแปลงรูปภาพมาไว้ที่ Service เพื่อไม่ให้ UI ทำงานหนัก
  Future<String> processImageToBase64(File file) async {
    Uint8List bytes = await file.readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return "";
    
    // ย่อขนาดรูปให้กว้าง 300px และบีบอัดคุณภาพเหลือ 70% เพื่อประหยัดพื้นที่ Firestore
    img.Image resized = img.copyResize(decoded, width: 300); 
    List<int> compressed = img.encodeJpg(resized, quality: 70);
    return base64Encode(compressed);
  }

  // ==========================================
  // 🟢 ส่วนที่เพิ่มใหม่สำหรับหน้า NotificationScreen (ข้อ B4)
  // ==========================================

  // B4: ดึงข้อมูลแจ้งเตือนและแปลงเป็น List<NotificationModel>
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('Users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromDoc(doc))
            .toList());
  }

  // ==========================================
  // ⚪️ โค้ดเดิมของคุณ (ไม่ถูกปรับเปลี่ยนการทำงาน)
  // ==========================================

  // อัปเดตข้อมูลโปรไฟล์
  Future<void> updateProfile({
    required String uid,
    required String email,
    required String displayName,
    required String phoneNumber,
    required String bio,
    String? base64Image,
  }) async {
    await _db.collection('Users').doc(uid).set({
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'profileImage': base64Image,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // มาร์คแจ้งเตือนว่าอ่านแล้ว
  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await _db
        .collection('Users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}