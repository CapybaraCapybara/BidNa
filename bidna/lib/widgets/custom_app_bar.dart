import 'dart:convert';
import 'package:bidna/pages/top_up_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/pages/notification_page.dart';
import 'package:bidna/pages/user_profile_view_page.dart';
import 'package:intl/intl.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? extraActions;

  const CustomAppBar({
    super.key,
    this.title = "BidNa",
    this.bottom,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6347EB),
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (extraActions != null) ...extraActions!,

        //  ส่วนที่เพิ่มใหม่: ปุ่มแสดงยอด Coupon
        Center(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                      .collection('Users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              int balance = 0;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                balance = (data['couponBalance'] ?? 0).toInt();
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopUpScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(
                    right: 12,
                  ), // ดันให้ห่างจากกระดิ่งนิดนึง
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6347EB).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_activity,
                        color: Color(0xFF6347EB),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        NumberFormat(
                          '#,###',
                        ).format(balance), // ใส่ Format ลูกน้ำ (เช่น 1,000)
                        style: const TextStyle(
                          color: Color(0xFF6347EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ปุ่มกระดิ่งแจ้งเตือนพร้อม Badge สีแดง
        Center(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                      .collection('Users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;
              return Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: Colors.redAccent,
                offset: const Offset(4, -4),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black,
                    size: 28, // ปรับขนาดให้พอดีขึ้นเมื่อมี Badge
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 12), // เพิ่มระยะห่างระหว่างกระดิ่งกับรูปโปรไฟล์
        // รูปโปรไฟล์มุมขวาบน (ดึงสดจาก Firestore)
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                      .collection('Users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              String? base64Image;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                base64Image = data?['profileImage'];
              }

              return GestureDetector(
                onTap: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileViewPage(targetUserId: uid),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      (base64Image != null && base64Image.isNotEmpty)
                      ? MemoryImage(base64Decode(base64Image))
                      : null,
                  child: (base64Image == null || base64Image.isEmpty)
                      ? const Icon(Icons.person, color: Colors.grey, size: 20)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
