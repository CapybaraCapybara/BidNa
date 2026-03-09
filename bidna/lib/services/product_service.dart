import 'package:cloud_firestore/cloud_firestore.dart';
// 🟢 อย่าลืม Import ProductModel สำหรับใช้ในเมธอดใหม่
import 'package:bidna/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // 🟢 ส่วนที่เพิ่มใหม่สำหรับหน้า MyBidPage (ข้อ B4)
  // ==========================================

  // B4: ดึงข้อมูลรายการที่ฉันประมูล (แปลงเป็น List<ProductModel> ให้เลยตั้งแต่ดึงข้อมูล)
  Stream<List<ProductModel>> getMyBidsStream(String userId) {
    return _db
        .collection('Products')
        .where('bidders', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromDoc(doc))
            .toList());
  }

  // B4: ดึงข้อมูลสินค้าที่ฉันลงขาย
  Stream<List<ProductModel>> getMyListingsStream(String userId) {
    return _db
        .collection('Products')
        .where('sellerUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromDoc(doc))
            .toList());
  }

  // B4: Business Logic เช็คว่าประมูลจบหรือยัง (ดึง Logic ออกจาก UI)
  bool isAuctionEnded(ProductModel product) {
    if (product.status.toLowerCase() == 'closed' || product.status.toLowerCase() == 'close') return true;
    if (product.endTime.isBefore(DateTime.now())) return true;
    return false;
  }

  // ==========================================
  // ⚪️ โค้ดเดิมของคุณ (ไม่ถูกปรับเปลี่ยนการทำงาน)
  // ==========================================

  // สร้างรายการประมูลใหม่
  Future<void> createListing(Map<String, dynamic> productData) async {
    await _db.collection('Products').add(productData);
  }

  // ดึงข้อมูลสินค้าทั้งหมดแบบ Stream
  Stream<QuerySnapshot> getLiveAuctions() {
    return _db
        .collection('Products')
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  // ปิดการประมูลอัตโนมัติ (เปลี่ยน status เป็น closed)
  Future<void> closeAuction(String productId) async {
    await _db.collection('Products').doc(productId).update({
      'status': 'closed',
    });
  }

  // วางเงินประมูล (Bid) และส่งแจ้งเตือนคนโดนปาดหน้า
  Future<void> placeBid({
    required String productId,
    required String myUid,
    required double amount,
    required String? previousWinnerId,
  }) async {
    // 1. ดึงข้อมูล User มาเช็คยอดเงินก่อน
    final userDoc = await _db.collection('Users').doc(myUid).get();
    final double myBalance =
        (userDoc.data() as Map<String, dynamic>)['couponBalance']?.toDouble() ??
        0;

    // 2. เช็คว่าเงินพอไหม?
    if (myBalance < amount) {
      throw Exception(
        'คูปองไม่เพียงพอ กรุณาเติมคูปอง!',
      ); // โยน Error กลับไปให้หน้า UI แจ้งเตือน
    }

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
      await _db
          .collection('Users')
          .doc(previousWinnerId)
          .collection('notifications')
          .add({
            'title': 'You have been outbid! 😱',
            'message':
                'Someone placed a higher bid of ฿${amount.toStringAsFixed(0)} on your item.',
            'isRead': false,
            'type': 'OUTBID',
            'productId': productId,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
  }

  // ชำระเงินเมื่อชนะการประมูล
  Future<void> payForWonAuction({
    required String productId,
    required String winnerUid,
    required double amount,
  }) async {
    // 1. ดึงข้อมูล User มาเช็คยอด Coupon
    final userDoc = await _db.collection('Users').doc(winnerUid).get();
    final double currentBalance =
        (userDoc.data() as Map<String, dynamic>?)?['couponBalance']
            ?.toDouble() ??
        0;

    // 2. ถ้าเงินไม่พอ ให้โยน Error กลับไปให้หน้า UI แจ้งเตือน
    if (currentBalance < amount) {
      throw Exception('คูปองไม่เพียงพอ กรุณาเติมคูปองที่หน้าโปรไฟล์!');
    }

    // 3. ใช้ WriteBatch เพื่อให้การหักเงินและการเปลี่ยนสถานะสินค้า "ทำงานพร้อมกัน"
    WriteBatch batch = _db.batch();

    // 3.1 หักเงินผู้ชนะ
    DocumentReference userRef = _db.collection('Users').doc(winnerUid);
    batch.update(userRef, {'couponBalance': FieldValue.increment(-amount)});

    // 3.2 เปลี่ยนสถานะสินค้าเป็น PAID
    DocumentReference productRef = _db.collection('Products').doc(productId);
    batch.update(productRef, {'status': 'PAID'});

    // ยืนยันการเปลี่ยนแปลงลงฐานข้อมูล
    await batch.commit();
  }

  //  ผู้ซื้อยืนยันการรับสินค้า (โอนเงินให้ผู้ขาย)
  Future<void> confirmItemReceipt({
    required String productId,
    required String sellerUid,
    required double amount,
  }) async {
    WriteBatch batch = _db.batch();

    // 1. นำ Coupon ไปบวกเพิ่มให้กับ "ผู้ขาย"
    DocumentReference sellerRef = _db.collection('Users').doc(sellerUid);
    batch.update(sellerRef, {'couponBalance': FieldValue.increment(amount)});

    // 2. อัปเดตสถานะสินค้าเป็น 'COMPLETED' (จบกระบวนการทั้งหมด)
    DocumentReference productRef = _db.collection('Products').doc(productId);
    batch.update(productRef, {'status': 'COMPLETED'});

    await batch.commit();
  }

  // 1. ดึง Stream ของสินค้าหน้า Detail
  Stream<DocumentSnapshot> getProductStream(String productId) {
    return _db.collection('Products').doc(productId).snapshots();
  }

  // 2. ดึง Stream ประวัติการประมูล
  Stream<QuerySnapshot> getBidHistoryStream(String productId) {
    return _db.collection('Products')
        .doc(productId)
        .collection('bids')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 3. ดึงข้อมูล User (ใช้ดึงได้ทั้งข้อมูลคนขาย และข้อมูลคนประมูล)
  Future<DocumentSnapshot> getUserData(String uid) {
    return _db.collection('Users').doc(uid).get();
  }

  // ดึงข้อมูล User แบบ Real-time (ใช้สำหรับดักฟังการเปลี่ยนแปลง Rating)
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('Users').doc(uid).snapshots();
  }
  
  Stream<QuerySnapshot> getSoldItemsStream(String sellerUid) {
    return _db.collection('Products')
        .where('sellerUid', isEqualTo: sellerUid)
        .where('status', isEqualTo: 'closed')
        .snapshots();
  }
}


