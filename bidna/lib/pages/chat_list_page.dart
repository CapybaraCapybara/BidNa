import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Models & Services
import 'package:bidna/models/chat_model.dart';
import 'package:bidna/services/chat_service.dart';
import 'package:bidna/services/auth_service.dart';

// Widgets (B4: แยก UI ออกจาก page)
import 'package:bidna/widgets/chat_room_tile.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

// B3: เปลี่ยนเป็น StatefulWidget เพื่อ init stream ครั้งเดียวใน initState
class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  User? _currentUser;

  // B3: เตรียม stream ล่วงหน้า ไม่สร้างใหม่ทุกรอบที่ build
  late final Stream<List<ChatRoomModel>> _chatRoomsStream;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();

    if (_currentUser != null) {
      // B4: ให้ Service จัดการ query + sort แทน UI
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
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: _chatRoomsStream,
        builder: (context, snapshot) {
          // B5: error handling
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
              // B2: format time sekali di sini, bukan di dalam widget
              final String timeAgo = room.lastTimestamp != null
                  ? DateFormat('HH:mm').format(room.lastTimestamp!)
                  : '';

              // B4: ใช้ ChatRoomTile widget แยกไฟล์
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
