import 'package:cloud_firestore/cloud_firestore.dart';

class TopUpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ฟังก์ชันจำลองการเติมเงิน (เพิ่ม Coupon)
  Future<void> processTopUp(String uid, int amount) async {
    // ใช้ SetOptions(merge: true) เผื่อกรณีที่ User คนนี้เพิ่งสมัครใหม่และยังไม่มีฟิลด์ couponBalance
    await _db.collection('Users').doc(uid).set({
      'couponBalance': FieldValue.increment(amount),
    }, SetOptions(merge: true));
  }
}