import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Models & Services
import 'package:bidna/models/review_model.dart';
import 'package:bidna/models/product_model.dart';
import 'package:bidna/services/review_service.dart';
import 'package:bidna/services/auth_service.dart';
import 'package:bidna/services/user_service.dart';
import 'package:bidna/services/product_service.dart';

// Pages
import 'package:bidna/pages/profile_edit_page.dart';
import 'package:bidna/pages/product_details_page.dart';

// Widgets (B4: แยก UI ออกจาก logic)
import 'package:bidna/widgets/profile_header_widget.dart';
import 'package:bidna/widgets/sold_item_card.dart';
import 'package:bidna/widgets/review_card.dart';

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
  double _rating = 0.0;
  int _ratingCount = 0;

  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  User? _currentUser;

  // B3: เตรียม Stream ไว้ล่วงหน้า ไม่สร้างใหม่ทุกครั้งที่ build
  late final Stream<QuerySnapshot> _soldItemsStream;
  late final Stream<List<ReviewModel>> _reviewsStream;

  bool get _isOwnProfile => _currentUser?.uid == widget.targetUserId;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    // B3: กำหนด stream ครั้งเดียวใน initState
    _soldItemsStream = _productService.getSoldItemsStream(widget.targetUserId);

    _reviewsStream = _reviewService.getSellerReviews(widget.targetUserId);

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final doc = await _userService.getUserData(widget.targetUserId);

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _displayName = data['displayName'] ?? 'Unknown User';
          _phoneNumber = data['phoneNumber'] ?? '';
          _bio = data['bio'] ?? '';
          _base64Image = data['profileImage'];
          _rating = (data['rating'] ?? 0.0).toDouble();
          _ratingCount = (data['ratingCount'] ?? 0).toInt();
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
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
        title: Text(
          _isOwnProfile ? 'My Profile' : 'Seller Profile',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF6347EB)),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // B4: ใช้ Widget แยกไฟล์แทนการเขียน UI ยาวใน page
            ProfileHeaderWidget(
              displayName: _displayName,
              phoneNumber: _phoneNumber,
              bio: _bio,
              base64Image: _base64Image,
              rating: _rating,
              ratingCount: _ratingCount,
            ),
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

  Widget _buildSoldItemsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Sold Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _soldItemsStream,
            builder: (context, snapshot) {
              // B5: error handling
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Unable to load sold items.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No sold items yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final soldProducts = snapshot.data!.docs
                  .map((doc) => ProductModel.fromDoc(doc))
                  .toList();

              return SizedBox(
                height: 160,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: soldProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  // B4: ใช้ SoldItemCard widget แยกไฟล์
                  itemBuilder: (context, index) => SoldItemCard(
                    product: soldProducts[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsPage(
                          productId: soldProducts[index].id,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
          const Text(
            'Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<ReviewModel>>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              // B5: error handling
              if (snapshot.hasError) {
                return const Text(
                  'Unable to load reviews.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey),
                );
              }

              final reviews = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 32, color: Color(0xFFEEEEEE)),
                // B4: ใช้ ReviewCard widget แยกไฟล์
                itemBuilder: (context, index) =>
                    ReviewCard(review: reviews[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}
