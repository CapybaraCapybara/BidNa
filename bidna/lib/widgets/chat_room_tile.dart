import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bidna/models/chat_model.dart';
import 'package:bidna/pages/chat_page.dart';
import 'package:bidna/services/user_service.dart';

/// Widget แสดง 1 แถวใน Chat List
class ChatRoomTile extends StatelessWidget {
  final ChatRoomModel room;
  final String currentUserId;
  final String timeAgo;

  const ChatRoomTile({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final String peerId = room.users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (peerId.isEmpty) return const SizedBox.shrink();

    final UserService userService = UserService();

    return StreamBuilder<DocumentSnapshot>(
      stream: userService.getUserStream(
        peerId,
      ), // ฟังการเปลี่ยนแปลงของเพื่อนตลอดเวลา
      builder: (context, snapshot) {
        // B5: รอข้อมูลโหลด
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('...'),
          );
        }

        // B5: error handling — ถ้าดึงข้อมูลไม่ได้ ไม่ crash
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        // 🌟 4. แปลงข้อมูลแบบ Map
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final peerName = data['displayName'] ?? 'Unknown';
        final String? peerImage = data['profileImage'];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          tileColor: Colors.white,
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (peerImage != null && peerImage.isNotEmpty)
                ? MemoryImage(base64Decode(peerImage))
                : null,
            child: (peerImage == null || peerImage.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          title: Text(
            peerName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            room.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            timeAgo,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                peerId: peerId,
                peerName: peerName,
                peerAvatarBase64: peerImage,
              ),
            ),
          ),
        );
      },
    );
  }
}
