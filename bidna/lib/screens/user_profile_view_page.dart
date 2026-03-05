import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bidna/models/review_model.dart';
import 'package:bidna/services/review_service.dart';
import 'package:bidna/screens/profile_page.dart';

class UserProfileViewPage extends StatefulWidget {
  final String targetUserId;

  const UserProfileViewPage({super.key, required this.targetUserId});

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  bool _isLoading = true;

  // ── ข้อมูลโปรไฟล์ ──
  String _displayName = '';
  String _phoneNumber = '';
  String _bio = '';
  String? _base64Image;
  String _email = '';
  double _rating = 0.0;
  int _ratingCount = 0;

  // ── สินค้าที่ขายแล้ว (จาก Products collection, field: sellerUid, status: sold) ──
  List<Map<String, dynamic>> _soldItems = [];

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ReviewService _reviewService = ReviewService();

  bool get _isOwnProfile => _currentUser?.uid == widget.targetUserId;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadUserData(), _loadSoldItems()]);
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.targetUserId)
          .get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        setState(() {
          _displayName = d['displayName'] ?? '';
          _phoneNumber = d['phoneNumber'] ?? '';
          _bio         = d['bio']         ?? '';
          _base64Image = d['profileImage'];
          _email       = d['email']       ?? '';
          _rating      = (d['rating']      ?? 0.0).toDouble();
          _ratingCount = (d['ratingCount'] ?? 0) as int;
        });
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    }
  }

  // ── ดึงสินค้าของ user แล้วกรองใน Dart ทั้งหมด (ไม่ต้องสร้าง index) ──
  Future<void> _loadSoldItems() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Products')
          .where('sellerUid', isEqualTo: widget.targetUserId)
          .get();

      final filtered = snap.docs
          .map((d) => {...d.data(), 'productId': d.id})
          .where((item) =>
              item['status'] == 'closed' &&
              (item['totalBids'] ?? 0) > 0)
          .toList();

      // เรียงจากใหม่ไปเก่า
      filtered.sort((a, b) {
        final aTime = (a['endTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (b['endTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

      setState(() => _soldItems = filtered);
    } catch (e) {
      debugPrint("Error loading sold items: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Profile' : (_displayName.isNotEmpty ? _displayName : 'Profile'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isOwnProfile)
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ).then((_) => _loadAllData()),
              icon: const Icon(Icons.settings_outlined, color: Colors.black87),
              tooltip: 'ตั้งค่าโปรไฟล์',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6347EB)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildInfoSection(),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildSoldHistorySection(),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildReviewsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ─── Header ───
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _base64Image != null && _base64Image!.isNotEmpty
                ? MemoryImage(base64Decode(_base64Image!))
                : null,
            child: (_base64Image == null || _base64Image!.isEmpty)
                ? const Icon(Icons.person, size: 55, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            _displayName.isNotEmpty ? _displayName : 'ไม่ระบุชื่อ',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(_email, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          _buildRatingBadge(),
        ],
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE0DBFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (i) {
            final val = i + 1;
            if (_rating >= val) return const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22);
            if (_rating >= val - 0.5) return const Icon(Icons.star_half_rounded, color: Color(0xFFFFC107), size: 22);
            return const Icon(Icons.star_outline_rounded, color: Color(0xFFCCCCCC), size: 22);
          }),
          const SizedBox(width: 8),
          Text(
            _ratingCount > 0 ? _rating.toStringAsFixed(1) : 'No rating',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(width: 4),
          Text('($_ratingCount รีวิว)', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ─── Info ───
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(icon: Icons.phone_outlined, label: 'เบอร์โทรศัพท์',
              value: _phoneNumber.isNotEmpty ? _phoneNumber : 'ไม่ระบุ'),
          const SizedBox(height: 16),
          const Text('เกี่ยวกับฉัน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(12)),
            child: Text(
              _bio.isNotEmpty ? _bio : 'ยังไม่ได้เพิ่มรายละเอียด',
              style: TextStyle(fontSize: 14, color: _bio.isNotEmpty ? Colors.black87 : Colors.grey, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF0EDFF), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF6347EB), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  // ─── Sold History ───
  Widget _buildSoldHistorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('สินค้าที่เคยขาย',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                Text('${_soldItems.length} รายการ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _soldItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text('ยังไม่มีสินค้าที่ขายไป',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                )
              : SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 24),
                    itemCount: _soldItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _buildSoldItemCard(_soldItems[i]),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSoldItemCard(Map<String, dynamic> item) {
    final List images = item['images'] ?? [];
    final String? imageBase64 = images.isNotEmpty ? images[0] : null;
    final String title = item['title'] ?? '';
    final double price = (item['currentPrice'] ?? 0).toDouble();
    final String priceFormatted = NumberFormat('#,###').format(price);

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: imageBase64 != null && imageBase64.isNotEmpty
                ? Image.memory(base64Decode(imageBase64), height: 95, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    height: 95, color: const Color(0xFFF0EDFF),
                    child: const Center(child: Icon(Icons.image_outlined, color: Color(0xFF6347EB), size: 32)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('฿$priceFormatted',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6347EB), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reviews Section ───
  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reviews',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 12),
          StreamBuilder<List<ReviewModel>>(
            stream: _reviewService.getSellerReviews(widget.targetUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6347EB)));
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return Text('ยังไม่มี review',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (_, i) => _buildReviewItem(reviews[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูป reviewer
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (review.reviewerImage != null && review.reviewerImage!.isNotEmpty)
                ? MemoryImage(base64Decode(review.reviewerImage!))
                : null,
            child: (review.reviewerImage == null || review.reviewerImage!.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(DateFormat('dd MMM yy').format(review.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 4),
                // ดาว
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < review.rating ? const Color(0xFFFFC107) : Colors.grey.shade300,
                    size: 16,
                  )),
                ),
                const SizedBox(height: 4),
                Text(review.productTitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text(review.comment,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}