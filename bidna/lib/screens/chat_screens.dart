import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

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
  final String myUid = FirebaseAuth.instance.currentUser!.uid;
  late String roomId;
  bool _isSendingImage = false;

  @override
  void initState() {
    super.initState();
    // สร้าง Room ID ให้เหมือนกันเสมอไม่ว่าใครทักก่อน
    List<String> ids = [myUid, widget.peerId];
    ids.sort();
    roomId = ids.join("_");
  }

  Future<void> _pickAndSendImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isSendingImage = true);
    
    File file = File(pickedFile.path);
    String base64String = await _processImageToBase64(file);
    
    await _sendMessage(null, base64String);
    setState(() => _isSendingImage = false);
  }

  Future<String> _processImageToBase64(File file) async {
    var bytes = await file.readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return "";
    img.Image resized = img.copyResize(decoded, width: 500);
    List<int> compressed = img.encodeJpg(resized, quality: 60);
    return base64Encode(compressed);
  }

  Future<void> _sendMessage(String? text, String? imageBase64) async {
    if ((text == null || text.trim().isEmpty) && imageBase64 == null) return;

    final msgData = {
      'senderId': myUid,
      'receiverId': widget.peerId,
      'text': text?.trim(),
      'image': imageBase64,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 1. บันทึกข้อความลง Subcollection
    await FirebaseFirestore.instance
        .collection('ChatRooms')
        .doc(roomId)
        .collection('messages')
        .add(msgData);

    // 2. อัปเดตข้อมูลห้องสนทนาล่าสุด
    await FirebaseFirestore.instance.collection('ChatRooms').doc(roomId).set({
      'users': [myUid, widget.peerId], // 🔴 สำคัญมาก ต้องมีบรรทัดนี้ Chat List ถึงจะเห็น
      'lastMessage': imageBase64 != null ? "📷 Sent an image" : text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // -----------------------------------------------------------------
    // 🌟 3. ส่ง Notification เข้าไปที่ in-app แจ้งเตือนของผู้รับ
    // -----------------------------------------------------------------
    // ดึงชื่อของเราเองก่อน เพื่อเอาไปบอกผู้รับว่าใครทักมา
    DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('Users').doc(myUid).get();
    String myName = "Someone";
    if (myDoc.exists) {
      myName = (myDoc.data() as Map<String, dynamic>)['displayName'] ?? "Someone";
    }

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.peerId) // เล็งไปที่เป้าหมาย (คนรับ)
        .collection('notifications')
        .add({
      'title': 'New Message',
      'message': '$myName sent you a message.',
      'isRead': false,
      'type': 'CHAT', // สร้าง Type ใหม่เป็น CHAT
      'peerId': myUid, // เก็บ ID ของเราไว้ เผื่อคนรับกดจากแจ้งเตือนจะได้เปิดแชทถูกคน
      'peerName': myName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (widget.peerAvatarBase64 != null && widget.peerAvatarBase64!.isNotEmpty)
                  ? MemoryImage(base64Decode(widget.peerAvatarBase64!))
                  : null,
              child: (widget.peerAvatarBase64 == null || widget.peerAvatarBase64!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.peerName,
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isSendingImage) 
            const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator(color: Color(0xFF6347EB))),
          _buildInputBox(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ChatRooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Say Hi! 👋", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          reverse: true, // ให้ข้อความใหม่สุดอยู่ล่างสุด
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            bool isMe = data['senderId'] == myUid;
            return _buildMessageBubble(data, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    Timestamp? ts = data['timestamp'] as Timestamp?;
    String timeStr = ts != null ? DateFormat('HH:mm').format(ts.toDate()) : "";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6347EB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (data['image'] != null && data['image'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(base64Decode(data['image']), fit: BoxFit.cover),
                ),
              ),
            if (data['text'] != null && data['text'].toString().isNotEmpty)
              Text(
                data['text'],
                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
              ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Color(0xFF6347EB)),
              onPressed: _pickAndSendImage,
            ),
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF6347EB)),
              onPressed: () => _sendMessage(_msgController.text, null),
            ),
          ],
        ),
      ),
    );
  }
}