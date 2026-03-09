import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Models & Services
import 'package:bidna/models/chat_model.dart';
import 'package:bidna/services/chat_service.dart';
import 'package:bidna/services/auth_service.dart';

// Widgets 
import 'package:bidna/widgets/chat_room_tile.dart';
// นำเข้า CustomAppBar
import 'package:bidna/widgets/custom_app_bar.dart'; 

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  User? _currentUser;

  late final Stream<List<ChatRoomModel>> _chatRoomsStream;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();

    if (_currentUser != null) {
      _chatRoomsStream = _chatService.getUserChatRoomsStream(_currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      // แก้ไข: เปลี่ยนจาก AppBar ปกติเป็น CustomAppBar
      appBar: const CustomAppBar(),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _chatRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load messages.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }

          final rooms = snapshot.data!;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final String timeAgo = room.lastTimestamp != null
                  ? DateFormat('HH:mm').format(room.lastTimestamp!)
                  : '';

              return ChatRoomTile(
                room: room,
                currentUserId: _currentUser!.uid,
                timeAgo: timeAgo,
              );
            },
          );
        },
      ),
    );
  }
}