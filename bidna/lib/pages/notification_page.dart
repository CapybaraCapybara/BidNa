import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/pages/product_details_page.dart';
import 'package:bidna/pages/chat_page.dart';

// 🔴 Import Service & Model
import 'package:bidna/models/notification_model.dart';
import 'package:bidna/services/user_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 🔴 เรียกใช้ Service
  final UserService _userService = UserService();

  String _getTimeAgo(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color bgColor;

    switch (type) {
      case 'OUTBID':
        iconData = Icons.gavel_rounded;
        bgColor = Colors.redAccent;
        break;
      case 'WON':
        iconData = Icons.emoji_events_rounded;
        bgColor = Colors.amber;
        break;
      case 'CHAT': 
        iconData = Icons.chat_bubble_rounded;
        bgColor = const Color(0xFF6347EB);
        break;
      default:
        iconData = Icons.notifications_active;
        bgColor = Colors.blue;
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: bgColor.withOpacity(0.15),
      child: Icon(iconData, color: bgColor, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {}, 
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login to see notifications."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notifications yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // 🔴 แปลง Document ให้เป็น Model
                final notifications = snapshot.data!.docs.map((doc) => NotificationModel.fromDoc(doc)).toList();

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    String timeAgo = _getTimeAgo(notif.createdAt);

                    return InkWell(
                      onTap: () async {
                        // 🔴 มาร์คว่าอ่านแล้วผ่าน Service
                        if (!notif.isRead) {
                          await _userService.markNotificationAsRead(currentUser.uid, notif.id);
                        }

                        if (!context.mounted) return;

                        if (notif.type == 'CHAT') {
                          if (notif.peerId != null && notif.peerId!.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  peerId: notif.peerId!,
                                  peerName: notif.peerName ?? "User",
                                ),
                              ),
                            );
                          }
                        } else if (notif.productId != null && notif.productId!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(productId: notif.productId!),
                            ),
                          );
                        }
                      },
                      child: Container(
                        color: notif.isRead ? Colors.white : const Color(0xFFE7F3FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNotificationIcon(notif.type),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "${notif.title} ",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: notif.message),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      color: notif.isRead
                                          ? Colors.grey[600]
                                          : const Color(0xFF1877F2),
                                      fontWeight: notif.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 12),
                                if (!notif.isRead)
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1877F2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}