import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/screens/product_details_page.dart';
import 'package:bidna/screens/chat_screens.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ฟังก์ชันแปลงเวลาแบบ Facebook (เช่น 5m, 2h, 1d)
  String _getTimeAgo(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  // ฟังก์ชันเลือก Icon และสีตามประเภทแจ้งเตือน (เผื่ออนาคตมีหลายแบบ)
  // Widget _buildNotificationIcon(String type) {
  //   IconData iconData;
  //   Color bgColor;

  //   switch (type) {
  //     case 'OUTBID':
  //       iconData = Icons.gavel_rounded;
  //       bgColor = Colors.redAccent;
  //       break;
  //     case 'WON':
  //       iconData = Icons.emoji_events_rounded;
  //       bgColor = Colors.amber;
  //       break;
  //     default:
  //       iconData = Icons.notifications_active;
  //       bgColor = Colors.blue;
  //   }

  //   return CircleAvatar(
  //     radius: 28,
  //     backgroundColor: bgColor.withOpacity(0.15),
  //     child: Icon(iconData, color: bgColor, size: 28),
  //   );
  // }
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
      case 'CHAT': // 🔴 เพิ่มไอคอนแชท
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
            onPressed: () {}, // เผื่อทำช่องค้นหา
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

                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notifDoc = notifications[index];
                    final data = notifDoc.data() as Map<String, dynamic>;

                    final String notifId = notifDoc.id;
                    final String title = data['title'] ?? "Notification";
                    final String message = data['message'] ?? "";
                    final bool isRead = data['isRead'] ?? false;
                    final String type = data['type'] ?? "SYSTEM";
                    final String productId = data['productId'] ?? "";

                    // แปลงเวลา
                    DateTime createdAt = DateTime.now();
                    if (data['createdAt'] != null) {
                      createdAt = (data['createdAt'] as Timestamp).toDate();
                    }
                    String timeAgo = _getTimeAgo(createdAt);

return InkWell(
                      onTap: () async {
                        if (!isRead) {
                          await FirebaseFirestore.instance
                              .collection('Users')
                              .doc(currentUser.uid)
                              .collection('notifications')
                              .doc(notifId)
                              .update({'isRead': true});
                        }

                        if (!context.mounted) return;

                        // 🔴 ถ้าเป็นการแจ้งเตือนแบบแชท ให้เปิดหน้า ChatScreen
                        if (type == 'CHAT') {
                          String pId = data['peerId'] ?? "";
                          String pName = data['peerName'] ?? "User";
                          if (pId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  peerId: pId,
                                  peerName: pName,
                                ),
                              ),
                            );
                          }
                        } 
                        // ถ้าเป็นการแจ้งเตือนประมูล ให้เปิดหน้าสินค้า
                        else if (productId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(productId: productId),
                            ),
                          );
                        }
                      },
                      child: Container(
                        color: isRead ? Colors.white : const Color(0xFFE7F3FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNotificationIcon(type),
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
                                          text: "$title ",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: message),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      color: isRead
                                          ? Colors.grey[600]
                                          : const Color(0xFF1877F2),
                                      fontWeight: isRead
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
                                if (!isRead)
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
