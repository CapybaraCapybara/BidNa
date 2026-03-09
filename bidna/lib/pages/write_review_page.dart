import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Models & Services
import 'package:bidna/services/review_service.dart';

// Widgets & Utils (B4: แยก UI และ logic ออกจาก page)
import 'package:bidna/widgets/star_rating_widget.dart';
import 'package:bidna/utils/rating_label.dart';

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
        const SnackBar(
          content: Text('กรุณาใส่ความคิดเห็นก่อนส่ง'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // B4: ให้ Service จัดการ logic ดึงข้อมูล reviewer และสร้าง ReviewModel
      final review = await _reviewService.buildReviewFromCurrentUser(
        reviewerUid: user.uid,
        sellerId: widget.sellerId,
        productId: widget.productId,
        productTitle: widget.productTitle,
        rating: _selectedRating,
        comment: comment,
      );

      await _reviewService.submitReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ขอบคุณสำหรับการรีวิว! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // B5: error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text(
          'Write a Review',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ให้คะแนนสินค้า "${widget.productTitle}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // B2: ใช้ helper function แทนการเขียน logic ซ้ำใน build
            Text(
              ratingLabel(_selectedRating),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6347EB),
              ),
            ),
            const SizedBox(height: 10),
            // B4: ใช้ StarRatingWidget แยกไฟล์แทนการ generate ใน build
            StarRatingWidget(
              rating: _selectedRating,
              onRatingChanged: (value) =>
                  setState(() => _selectedRating = value),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'แบ่งปันประสบการณ์ของคุณเกี่ยวกับสินค้านี้...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6347EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}