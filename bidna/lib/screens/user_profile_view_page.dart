import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/screens/profile_page.dart'; // แก้ path ให้ตรงกับโปรเจกต์คุณ

class UserProfileViewPage extends StatefulWidget {
  final String targetUserId; // UID ของคนที่เราจะดูโปรไฟล์

  const UserProfileViewPage({super.key, required this.targetUserId});

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  bool _isLoading = true;

  // ── ข้อมูลโปรไฟล์ (ดึงจาก Users collection) ──
  String _displayName = '';
  String _phoneNumber = '';
  String _bio = '';
  String? _base64Image;
  String _email = '';

  // ── Rating ──
  // TODO: เมื่อทำ rating feature แล้ว ให้เพิ่ม field 'rating' (double) และ 'ratingCount' (int)
  //       ใน Users collection แล้ว uncomment บรรทัดใน _loadUserData()
  double _rating = 4.3;  // mock
  int _ratingCount = 12; // mock

  // ── ประวัติสินค้าที่เคยขาย ──
  // TODO: เมื่อพร้อมให้ดึงจาก posts collection โดย:
  //       .where('userId', isEqualTo: widget.targetUserId)
  //       .where('status', isEqualTo: 'sold')
  //       field ที่ใช้แสดง: 'title', 'price', 'imageBase64'
  final List<Map<String, dynamic>> _soldItems = [
    {'title': 'Nike Air Max 90',     'price': 2500,  'imageBase64': null},
    {'title': 'Vintage Leather Bag', 'price': 1800,  'imageBase64': null},
    {'title': 'Sony WH-1000XM4',     'price': 6500,  'imageBase64': null},
    {'title': 'iPad Pro 11"',        'price': 18000, 'imageBase64': null},
    {'title': 'Mechanical Keyboard', 'price': 3200,  'imageBase64': null},
  ];

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // true = กำลังดูโปรไฟล์ตัวเอง → แสดงปุ่มตั้งค่า
  bool get _isOwnProfile => _currentUser?.uid == widget.targetUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.targetUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _displayName = data['displayName'] ?? '';
          _phoneNumber = data['phoneNumber'] ?? '';
          _bio         = data['bio']         ?? '';
          _base64Image = data['profileImage'];
          _email       = data['email']       ?? '';

          // TODO: uncomment เมื่อเพิ่ม field rating ใน Firestore
          // _rating      = (data['rating']      ?? 0.0).toDouble();
          // _ratingCount = (data['ratingCount'] ?? 0) as int;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
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
          // ── ปุ่มตั้งค่า: แสดงเฉพาะเมื่อดูโปรไฟล์ตัวเอง ──
          if (_isOwnProfile)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ).then((_) => _loadUserData()); // รีโหลดข้อมูลหลังกลับมา
              },
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────
  // Header: รูปโปรไฟล์ + ชื่อ + อีเมล + Rating
  // ─────────────────────────────────────────
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

  // ─────────────────────────────────────────
  // Rating Badge: ดาว + ตัวเลข + จำนวนรีวิว
  // ─────────────────────────────────────────
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
          // ดาว 5 ดวง (รองรับครึ่งดาว)
          ...List.generate(5, (i) {
            final val = i + 1;
            if (_rating >= val) {
              return const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22);
            } else if (_rating >= val - 0.5) {
              return const Icon(Icons.star_half_rounded, color: Color(0xFFFFC107), size: 22);
            } else {
              return const Icon(Icons.star_outline_rounded, color: Color(0xFFCCCCCC), size: 22);
            }
          }),
          const SizedBox(width: 8),
          Text(
            _rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(width: 4),
          Text('($_ratingCount รีวิว)', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Info: เบอร์โทร + Bio
  // ─────────────────────────────────────────
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'เบอร์โทรศัพท์',
            value: _phoneNumber.isNotEmpty ? _phoneNumber : 'ไม่ระบุ',
          ),
          const SizedBox(height: 16),
          const Text(
            'เกี่ยวกับฉัน',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _bio.isNotEmpty ? _bio : 'ยังไม่ได้เพิ่มรายละเอียด',
              style: TextStyle(
                fontSize: 14,
                color: _bio.isNotEmpty ? Colors.black87 : Colors.grey,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6347EB), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Sold History: รายการสินค้าที่เคยขาย (scroll แนวนอน)
  // ─────────────────────────────────────────
  Widget _buildSoldHistorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'สินค้าที่เคยขาย',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
                Text(
                  '${_soldItems.length} รายการ',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _soldItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 24, bottom: 8),
                  child: Text(
                    'ยังไม่มีสินค้าที่ขายไป',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
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
    final String? imageBase64 = item['imageBase64'];
    final String title = item['title'] ?? '';
    final int price = item['price'] ?? 0;

    final String priceFormatted = price
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: imageBase64 != null && imageBase64.isNotEmpty
                ? Image.memory(
                    base64Decode(imageBase64),
                    height: 95,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 95,
                    color: const Color(0xFFF0EDFF),
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: Color(0xFF6347EB), size: 32),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '฿$priceFormatted',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6347EB), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}