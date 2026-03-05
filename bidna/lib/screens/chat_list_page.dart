import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/screens/chat_screens.dart';
import 'package:intl/intl.dart';

// 🔴 Import Model
import 'package:bidna/models/chat_model.dart';

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

          // 🔴 แปลง Document เป็น ChatRoomModel
          var rooms = snapshot.data!.docs.map((doc) => ChatRoomModel.fromDoc(doc)).toList();
          
          // 🔴 เรียงลำดับโดยใช้ Property ของ Model
          rooms.sort((a, b) {
            if (a.lastTimestamp == null && b.lastTimestamp == null) return 0;
            if (a.lastTimestamp == null) return 1;
            if (b.lastTimestamp == null) return -1;
            return b.lastTimestamp!.compareTo(a.lastTimestamp!);
          });

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index];
              // 🔴 หา peerId จาก Model
              String peerId = room.users.firstWhere((id) => id != currentUser.uid, orElse: () => "");
              
              if (peerId.isEmpty) return const SizedBox.shrink();

              String timeAgo = room.lastTimestamp != null 
                  ? DateFormat('HH:mm').format(room.lastTimestamp!) 
                  : "";

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
                    subtitle: Text(room.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
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