import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/pages/product_details_page.dart';
import 'package:bidna/pages/chat_page.dart';

// Models & Services
import 'package:bidna/models/notification_model.dart';
import 'package:bidna/services/user_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final UserService _userService = UserService();

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
      ),
      body: currentUser == null
          ? const Center(child: Text("Please login to see notifications."))
          : StreamBuilder<List<NotificationModel>>(
              // B4: เรียกผ่าน Service
              stream: _userService.getNotificationsStream(currentUser.uid),
              builder: (context, snapshot) {
                // B5: Error Handling
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error loading notifications."),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notifications yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final notifications = snapshot.data!;

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    // B2: ใช้ Widget ที่แยกออกมาเพื่อความ Clean
                    return NotificationTile(
                      notification: notif,
                      currentUserId: currentUser.uid,
                      userService: _userService,
                    );
                  },
                );
              },
            ),
    );
  }
}

// ======================================================================
// B2: แยก NotificationTile ออกมา (สามารถนำไปไว้ที่โฟลเดอร์ widgets/ ได้)
// ======================================================================

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String currentUserId;
  final UserService userService;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.currentUserId,
    required this.userService,
  });

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
    String timeAgo = _getTimeAgo(notification.createdAt);

    return InkWell(
      onTap: () async {
        // อัปเดตสถานะเป็น "อ่านแล้ว"
        if (!notification.isRead) {
          await userService.markNotificationAsRead(
            currentUserId,
            notification.id,
          );
        }

        if (!context.mounted) return;

        // B3: Flow การนำทาง
        if (notification.type == 'CHAT') {
          if (notification.peerId != null && notification.peerId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  peerId: notification.peerId!,
                  peerName: notification.peerName ?? "User",
                ),
              ),
            );
          }
        } else if (notification.productId != null &&
            notification.productId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsPage(productId: notification.productId!),
            ),
          );
        }
      },
      child: Container(
        color: notification.isRead ? Colors.white : const Color(0xFFE7F3FF),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                      children: [
                        TextSpan(
                          text: "${notification.title} ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: notification.message),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: notification.isRead
                          ? Colors.grey[600]
                          : const Color(0xFF1877F2),
                      fontWeight: notification.isRead
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
                if (!notification.isRead)
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
  }
}
