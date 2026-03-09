import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

// Models & Services
import 'package:bidna/services/chat_service.dart';
import 'package:bidna/models/chat_model.dart';

// Widgets (B4: แยก UI ออกจาก page)
import 'package:bidna/widgets/message_bubble.dart';
import 'package:bidna/widgets/chat_input_box.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? peerAvatarBase64;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerAvatarBase64,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  late final String _roomId;
  late final Stream<QuerySnapshot> _messagesStream;

  bool _isSendingImage = false;

  @override
  void initState() {
    super.initState();
    _roomId = _chatService.getRoomId(_myUid, widget.peerId);

    // B3: init stream ครั้งเดียวใน initState
    _messagesStream = FirebaseFirestore.instance
        .collection('ChatRooms')
        .doc(_roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isSendingImage = true);
    try {
      // B4: ให้ Service จัดการ image processing
      final base64String =
          await _chatService.processImageToBase64(File(pickedFile.path));
      await _sendMessage(null, base64String);
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  Future<void> _sendMessage(String? text, String? imageBase64) async {
    if ((text == null || text.trim().isEmpty) && imageBase64 == null) return;

    // B4: ให้ Service ดึง sender name แทน UI
    final myName = await _chatService.getSenderName(_myUid);

    await _chatService.sendMessage(
      roomId: _roomId,
      senderId: _myUid,
      receiverId: widget.peerId,
      senderName: myName,
      text: text,
      imageBase64: imageBase64,
    );

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (widget.peerAvatarBase64 != null &&
                      widget.peerAvatarBase64!.isNotEmpty)
                  ? MemoryImage(base64Decode(widget.peerAvatarBase64!))
                  : null,
              child: (widget.peerAvatarBase64 == null ||
                      widget.peerAvatarBase64!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.peerName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isSendingImage)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Color(0xFF6347EB)),
            ),
          // B4: ใช้ ChatInputBox widget แยกไฟล์
          ChatInputBox(
            controller: _msgController,
            onSendText: () => _sendMessage(_msgController.text, null),
            onPickImage: _pickAndSendImage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      // B3: ใช้ stream ที่ init ไว้แล้ว
      stream: _messagesStream,
      builder: (context, snapshot) {
        // B5: error handling
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load messages.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Say Hi! 👋', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final message =
                MessageModel.fromDoc(snapshot.data!.docs[index]);
            // B4: ใช้ MessageBubble widget แยกไฟล์
            return MessageBubble(
              message: message,
              isMe: message.senderId == _myUid,
            );
          },
        );
      },
    );
  }
}