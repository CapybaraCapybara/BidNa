import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUserData(String uid) {
    return _db.collection('Users').doc(uid).get();
  }

  // 🌟 2. ดึงข้อมูล User แบบ Real-time (Stream) สำหรับดักฟังดาว/รีวิว
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('Users').doc(uid).snapshots();
  }

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