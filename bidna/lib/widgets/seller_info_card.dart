import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bidna/pages/chat_page.dart';
import 'package:bidna/pages/user_profile_view_page.dart';
import 'package:bidna/services/product_service.dart';
import 'package:bidna/services/user_service.dart';

class SellerInfoCard extends StatelessWidget {
  final String sellerUid;
  final String? currentUserUid;
  final UserService userService;

  const SellerInfoCard({
    super.key,
    required this.sellerUid,
    required this.currentUserUid,
    required this.userService
  });

  @override
  Widget build(BuildContext context) {
    if (sellerUid.isEmpty) return const SizedBox.shrink();

    String fallbackSellerName = "Unknown Seller";

    // เปลี่ยนมาใช้ StreamBuilder เพื่อให้ข้อมูลดาว/รีวิว อัปเดตแบบ Real-time
    return StreamBuilder<DocumentSnapshot>(
      stream: userService.getUserStream(
        sellerUid,
      ), // เรียกใช้ Stream แทน Future
      builder: (context, userSnapshot) {
        String displaySellerName = fallbackSellerName;
        String? profileImageBase64;
        double sellerRating = 0.0;
        int sellerRatingCount = 0;

        // ปรับเงื่อนไขการเช็คข้อมูลของ Stream เล็กน้อย
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          displaySellerName = userData['displayName'] ?? fallbackSellerName;
          profileImageBase64 = userData['profileImage'];
          sellerRating = (userData['rating'] ?? 0.0).toDouble();
          sellerRatingCount = (userData['ratingCount'] ?? 0).toInt();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (sellerUid.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfileViewPage(targetUserId: sellerUid),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              (profileImageBase64 != null &&
                                  profileImageBase64.isNotEmpty)
                              ? MemoryImage(base64Decode(profileImageBase64))
                              : null,
                          child:
                              (profileImageBase64 == null ||
                                  profileImageBase64.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displaySellerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                Text(
                                  // แสดงข้อมูลแบบสดๆ
                                  '${sellerRatingCount > 0 ? sellerRating.toStringAsFixed(1) : "N/A"} • $sellerRatingCount reviews',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      if (currentUserUid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("กรุณาเข้าสู่ระบบเพื่อแชท"),
                          ),
                        );
                        return;
                      }
                      if (currentUserUid == sellerUid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("คุณไม่สามารถแชทกับตัวเองได้"),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            peerId: sellerUid,
                            peerName: displaySellerName,
                            peerAvatarBase64: profileImageBase64,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Chat",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
