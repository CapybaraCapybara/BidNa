import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 🔴 Import Models & Services
import 'package:bidna/models/review_model.dart';
import 'package:bidna/models/product_model.dart';
import 'package:bidna/services/review_service.dart';
import 'package:bidna/pages/profile_page.dart';
import 'package:bidna/pages/product_details_page.dart';

class UserProfileViewPage extends StatefulWidget {
  final String targetUserId;

  const UserProfileViewPage({super.key, required this.targetUserId});

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  bool _isLoading = true;

  String _displayName = '';
  String _phoneNumber = '';
  String _bio = '';
  String? _base64Image;
  String _email = '';
  double _rating = 0.0;
  int _ratingCount = 0;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ReviewService _reviewService = ReviewService();

  bool get _isOwnProfile => _currentUser?.uid == widget.targetUserId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.targetUserId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _displayName = data['displayName'] ?? 'Unknown User';
          _phoneNumber = data['phoneNumber'] ?? '';
          _bio = data['bio'] ?? '';
          _base64Image = data['profileImage'];
          _email = data['email'] ?? '';
          _rating = (data['rating'] ?? 0.0).toDouble();
          _ratingCount = (data['ratingCount'] ?? 0).toInt();
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(_isOwnProfile ? "My Profile" : "Seller Profile", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF6347EB)),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 10),
            _buildSoldItemsSection(),
            const SizedBox(height: 10),
            _buildReviewsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (_base64Image != null && _base64Image!.isNotEmpty) ? MemoryImage(base64Decode(_base64Image!)) : null,
            child: (_base64Image == null || _base64Image!.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
          ),
          const SizedBox(height: 16),
          Text(_displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 20),
              const SizedBox(width: 4),
              Text(
                '${_ratingCount > 0 ? _rating.toStringAsFixed(1) : "N/A"} (${_ratingCount} reviews)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_bio.isNotEmpty)
            Text(_bio, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSoldItemsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text("Sold Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            // 🔴 ดึงสินค้าที่ปิดประมูลแล้วของคนนี้
            stream: FirebaseFirestore.instance
                .collection('Products')
                .where('sellerUid', isEqualTo: widget.targetUserId)
                .where('status', isEqualTo: 'closed')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text("No sold items yet.", style: TextStyle(color: Colors.grey)),
                );
              }

              // 🔴 แปลง Document เป็น ProductModel
              final soldProducts = snapshot.data!.docs.map((doc) => ProductModel.fromDoc(doc)).toList();

              return SizedBox(
                height: 160,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: soldProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final product = soldProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(productId: product.id)));
                      },
                      child: _buildSoldItemCard(product), // 🔴 โยน ProductModel เข้าไป
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔴 ปรับให้รับ ProductModel
  Widget _buildSoldItemCard(ProductModel product) {
    final String? imageBase64 = product.images.isNotEmpty ? product.images[0] : null;
    final String priceFormatted = NumberFormat('#,###').format(product.currentPrice);

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: imageBase64 != null
                ? Image.memory(base64Decode(imageBase64), height: 95, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 95, color: const Color(0xFFF0EDFF), child: const Center(child: Icon(Icons.image, color: Color(0xFF6347EB)))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('฿$priceFormatted', style: const TextStyle(fontSize: 12, color: Color(0xFF6347EB), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<List<ReviewModel>>(
            stream: _reviewService.getSellerReviews(widget.targetUserId), // 🔴 ใช้ Service
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("No reviews yet.", style: TextStyle(color: Colors.grey));

              final reviews = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 32, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) => _buildReviewCard(reviews[index]), // 🔴 โยน ReviewModel เข้าไป
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔴 ปรับให้รับ ReviewModel
  Widget _buildReviewCard(ReviewModel review) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (review.reviewerImage != null && review.reviewerImage!.isNotEmpty) ? MemoryImage(base64Decode(review.reviewerImage!)) : null,
          child: (review.reviewerImage == null || review.reviewerImage!.isEmpty) ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(DateFormat('dd MMM yy').format(review.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < review.rating ? const Color(0xFFFFC107) : Colors.grey.shade300,
                  size: 16,
                )),
              ),
              const SizedBox(height: 4),
              Text(review.productTitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(review.comment, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}