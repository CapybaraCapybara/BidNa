import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bidna/models/review_model.dart';
import 'package:bidna/services/review_service.dart';

class WriteReviewPage extends StatefulWidget {
  final String productId;
  final String productTitle;
  final String sellerId;

  const WriteReviewPage({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.sellerId,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _commentController = TextEditingController();
  final _reviewService = ReviewService();

  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ความคิดเห็นก่อนส่ง'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;

      // ดึงข้อมูล reviewer
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      final review = ReviewModel(
        reviewId:      '',
        reviewerId:    currentUser.uid,
        reviewerName:  userData['displayName'] ?? 'Anonymous',
        reviewerImage: userData['profileImage'],
        sellerId:      widget.sellerId,
        productId:     widget.productId,
        productTitle:  widget.productTitle,
        rating:        _selectedRating,
        comment:       comment,
        createdAt:     DateTime.now(),
      );

      await _reviewService.submitReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่ง Review สำเร็จ! ขอบคุณครับ 🙏'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // ส่ง true กลับเพื่อบอกว่า review สำเร็จ
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Write a Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อสินค้า
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DBFF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: Color(0xFF6347EB), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.productTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // เลือกดาว
            const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starVal = (i + 1).toDouble();
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = starVal),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      _selectedRating >= starVal ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _selectedRating >= starVal ? const Color(0xFFFFC107) : Colors.grey.shade300,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _ratingLabel(_selectedRating),
                  style: const TextStyle(color: Color(0xFF6347EB), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ช่องความคิดเห็น
            const Text('Comment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'แชร์ประสบการณ์ของคุณกับผู้ขายคนนี้...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
            const SizedBox(height: 32),

            // ปุ่ม Submit
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6347EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating >= 5) return 'Excellent! ⭐';
    if (rating >= 4) return 'Good 👍';
    if (rating >= 3) return 'Okay 😐';
    if (rating >= 2) return 'Poor 👎';
    return 'Terrible 😞';
  }
}