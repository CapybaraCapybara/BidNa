import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // สร้างรายการประมูลใหม่
  Future<void> createListing(Map<String, dynamic> productData) async {
    await _db.collection('Products').add(productData);
  }

  // ดึงข้อมูลสินค้าทั้งหมดแบบ Stream
  Stream<QuerySnapshot> getLiveAuctions() {
    return _db.collection('Products').orderBy('startTime', descending: true).snapshots();
  }

  // ปิดการประมูลอัตโนมัติ (เปลี่ยน status เป็น closed)
  Future<void> closeAuction(String productId) async {
    await _db.collection('Products').doc(productId).update({'status': 'closed'});
  }

  // วางเงินประมูล (Bid) และส่งแจ้งเตือนคนโดนปาดหน้า
  Future<void> placeBid({
    required String productId,
    required String myUid,
    required double amount,
    required String? previousWinnerId,
  }) async {
    final productRef = _db.collection('Products').doc(productId);

    // อัปเดตข้อมูลสินค้า
    await productRef.update({
      'currentPrice': amount,
      'totalBids': FieldValue.increment(1),
      'bidders': FieldValue.arrayUnion([myUid]),
      'highestBidderUid': myUid,
    });

    // เพิ่มประวัติการประมูล
    await productRef.collection('bids').add({
      'price': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': myUid,
    });

    // แจ้งเตือนคนโดนปาด
    if (previousWinnerId != null && previousWinnerId != myUid) {
      await _db.collection('Users').doc(previousWinnerId).collection('notifications').add({
        'title': 'You have been outbid! 😱',
        'message': 'Someone placed a higher bid of ฿${amount.toStringAsFixed(0)} on your item.',
        'isRead': false,
        'type': 'OUTBID',
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}