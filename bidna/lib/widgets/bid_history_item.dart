import 'dart:convert'; // 🌟 เพิ่ม import นี้สำหรับ decode รูป
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BidHistoryItem extends StatelessWidget {
  final String username;
  final String timeAgo;
  final double amount;
  final String? profileImageBase64; // 🌟 เปลี่ยนชื่อให้ชัดเจนว่าเป็น Base64
  final bool isHighest; 

  const BidHistoryItem({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.amount,
    this.profileImageBase64, // 🌟 รับค่า Base64
    this.isHighest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighest ? const Color(0xFFF5F6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighest
            ? Border.all(color: const Color(0xFF6067ED).withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // 1. รูปโปรไฟล์
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            // 🌟 แก้ไขการดึงรูปให้รองรับ Base64
            backgroundImage: (profileImageBase64 != null && profileImageBase64!.isNotEmpty)
                ? MemoryImage(base64Decode(profileImageBase64!))
                : null,
            child: (profileImageBase64 == null || profileImageBase64!.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),

          // 2. ชื่อและเวลา 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge "HIGHEST"
                    if (isHighest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6067ED),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "HIGHEST",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 3. ยอดเงิน
          Text(
            "฿${NumberFormat('#,###').format(amount)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighest ? const Color(0xFF6067ED) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}