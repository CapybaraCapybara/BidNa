import 'package:flutter/material.dart';

/// Widget กล่องพิมพ์ข้อความด้านล่าง chat
class ChatInputBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;

  const ChatInputBox({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.image_outlined,
                color: Color(0xFF6347EB),
              ),
              onPressed: onPickImage,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Color(0xFF6347EB),
              ),
              onPressed: onSendText,
            ),
          ],
        ),
      ),
    );
  }
}