import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/screens/chat_screens.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. ดึงแค่ข้อมูลที่มีเราอยู่ (ประหยัดค่า Read) ตัด .orderBy ออกไปเลย!
        stream: FirebaseFirestore.instance
            .collection('ChatRooms')
            .where('users', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No messages yet."));
          }

          // 2. เอาข้อมูลมาจัดเรียง (Sort) ด้วยโค้ด Dart แทน (เหมือน Order By DESC)
          var rooms = snapshot.data!.docs.toList();
          rooms.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime = aData['lastTimestamp'] as Timestamp?;
            Timestamp? bTime = bData['lastTimestamp'] as Timestamp?;
            
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            // เรียงจากเวลาล่าสุดไปเก่าสุด
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var roomData = rooms[index].data() as Map<String, dynamic>;
              List users = roomData['users'] ?? [];
              String peerId = users.firstWhere((id) => id != currentUser.uid, orElse: () => "");
              
              if (peerId.isEmpty) return const SizedBox.shrink();

              String timeAgo = "";
              if (roomData['lastTimestamp'] != null) {
                timeAgo = DateFormat('HH:mm').format((roomData['lastTimestamp'] as Timestamp).toDate());
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('Users').doc(peerId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
                  var userData = userSnap.data!.data() as Map<String, dynamic>;
                  
                  String peerName = userData['displayName'] ?? "Unknown";
                  String? peerImage = userData['profileImage'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    tileColor: Colors.white,
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (peerImage != null && peerImage.isNotEmpty) ? MemoryImage(base64Decode(peerImage)) : null,
                      child: (peerImage == null || peerImage.isEmpty) ? const Icon(Icons.person, color: Colors.grey) : null,
                    ),
                    title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(roomData['lastMessage'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            peerId: peerId,
                            peerName: peerName,
                            peerAvatarBase64: peerImage,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}