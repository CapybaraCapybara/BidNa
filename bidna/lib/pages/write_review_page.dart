import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔴 Import Model & Service
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // ดึงข้อมูลคนรีวิว (ชื่อ, รูป)
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      String reviewerName = 'Anonymous';
      String? reviewerImage;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        reviewerName = data['displayName'] ?? 'Anonymous';
        reviewerImage = data['profileImage'];
      }

      // 🔴 สร้าง ReviewModel ให้ครบถ้วน
      final review = ReviewModel(
        reviewId: '', // จะถูก Auto-Generate ใน Service
        reviewerId: user.uid,
        reviewerName: reviewerName,
        reviewerImage: reviewerImage,
        sellerId: widget.sellerId,
        productId: widget.productId,
        productTitle: widget.productTitle,
        rating: _selectedRating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      // 🔴 เรียกใช้ Service บันทึกรีวิวและอัปเดต Rating คนขายอัตโนมัติ
      await _reviewService.submitReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ขอบคุณสำหรับการรีวิว! 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // ปิดหน้าต่างรีวิว
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
        title: const Text("Write a Review", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('ให้คะแนนสินค้า "${widget.productTitle}"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(_ratingLabel(_selectedRating), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6347EB))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _selectedRating ? const Color(0xFFFFC107) : Colors.grey.shade300,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _selectedRating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "แบ่งปันประสบการณ์ของคุณเกี่ยวกับสินค้านี้...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8F9FD),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating >= 5) return 'ยอดเยี่ยม! ⭐';
    if (rating >= 4) return 'ดีมาก 👍';
    if (rating >= 3) return 'พอใช้ 😐';
    if (rating >= 2) return 'ควรปรับปรุง 👎';
    return 'แย่มาก 😞';
  }
}