import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bidna/models/review_model.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;

  // ── ส่ง review และอัปเดต rating ของ seller อัตโนมัติ ──
  Future<void> submitReview(ReviewModel review) async {
    final batch = _db.batch();

    // 1. เขียน review ลง subcollection ของ seller
    final reviewRef = _db
        .collection('Users')
        .doc(review.sellerId)
        .collection('reviews')
        .doc(); // auto-id
    batch.set(reviewRef, review.toMap());

    // 2. mark ว่า product นี้ถูก review แล้ว (ป้องกัน review ซ้ำ)
    final productRef = _db.collection('Products').doc(review.productId);
    batch.update(productRef, {
      'isReviewed': true,
      'reviewedBy': review.reviewerId,
    });

    await batch.commit();

    // 3. คำนวณ rating ใหม่ของ seller
    await _recalculateSellerRating(review.sellerId);

    // 4. แจ้ง seller ว่าถูก review
    await _notifySeller(review);
  }

  // ── คำนวณ average rating จาก reviews ทั้งหมดของ seller ──
  Future<void> _recalculateSellerRating(String sellerId) async {
    final snapshot = await _db
        .collection('Users')
        .doc(sellerId)
        .collection('reviews')
        .get();

    if (snapshot.docs.isEmpty) return;

    final total = snapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + ((doc.data()['rating'] ?? 0) as num).toDouble(),
    );
    final avg = total / snapshot.docs.length;

    await _db.collection('Users').doc(sellerId).update({
      'rating':      double.parse(avg.toStringAsFixed(1)),
      'ratingCount': snapshot.docs.length,
    });
  }

  // ── แจ้ง seller ว่ามีคน review ──
  Future<void> _notifySeller(ReviewModel review) async {
    final stars = '⭐' * review.rating.round();
    await _db
        .collection('Users')
        .doc(review.sellerId)
        .collection('notifications')
        .add({
      'title':     'You got a new review! $stars',
      'message':   '${review.reviewerName} rated you ${review.rating.toStringAsFixed(1)} for "${review.productTitle}"',
      'isRead':    false,
      'type':      'NEW_REVIEW',
      'productId': review.productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── แจ้งผู้ชนะประมูลให้ไป review (เรียกหลังประมูลจบ) ──
  // เรียกใช้จาก Cloud Function หรือจากหน้า ProductDetails เมื่อ endTime ผ่านแล้ว
  Future<void> notifyWinnerToReview({
    required String winnerId,
    required String productId,
    required String productTitle,
  }) async {
    // เช็คก่อนว่าส่ง notification นี้ไปแล้วหรือยัง (ไม่ส่งซ้ำ)
    final existing = await _db
        .collection('Users')
        .doc(winnerId)
        .collection('notifications')
        .where('type',      isEqualTo: 'REVIEW_REMINDER')
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // ส่งไปแล้ว ไม่ส่งซ้ำ

    await _db
        .collection('Users')
        .doc(winnerId)
        .collection('notifications')
        .add({
      'title':     'Congratulations! You won the auction 🎉',
      'message':   'Don\'t forget to leave a review for "$productTitle"',
      'isRead':    false,
      'type':      'REVIEW_REMINDER',
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── เช็คว่า user นี้รีวิว product นี้ไปแล้วหรือยัง ──
  Future<bool> hasReviewed({
    required String sellerId,
    required String reviewerId,
    required String productId,
  }) async {
    final snapshot = await _db
        .collection('Users')
        .doc(sellerId)
        .collection('reviews')
        .where('reviewerId', isEqualTo: reviewerId)
        .where('productId',  isEqualTo: productId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ── ดึง reviews ทั้งหมดของ seller (ใช้ใน UserProfileViewPage) ──
  Stream<List<ReviewModel>> getSellerReviews(String sellerId) {
    return _db
        .collection('Users')
        .doc(sellerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReviewModel.fromDoc).toList());
  }
}