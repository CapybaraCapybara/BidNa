import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. ดึงข้อมูลยอดเงินแบบ Real-time (สำหรับหน้า UI)
  Stream<DocumentSnapshot> getUserBalanceStream(String uid) {
    return _db.collection('Users').doc(uid).snapshots();
  }

  // 2. ดึงยอดเงินปัจจุบันแบบครั้งเดียว (เพื่อเช็คก่อนถอน)
  Future<int> getCurrentBalance(String uid) async {
    final snapshot = await _db.collection('Users').doc(uid).get();
    if (snapshot.exists && snapshot.data() != null) {
      return (snapshot.data()!['couponBalance'] ?? 0).toInt();
    }
    return 0;
  }

  // 3. ทำคำสั่งหักเงิน (Mockup ถอนเงิน)
  Future<void> processWithdraw(String uid, int amount) async {
    await _db.collection('Users').doc(uid).update({
      'couponBalance': FieldValue.increment(-amount),
    });
  }
}