import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BidHistoryItem extends StatelessWidget {
  final String username;
  final String timeAgo;
  final double amount;
  final String? avatarUrl; // สำหรับรูปโปรไฟล์ (ถ้ามี)
  final bool isHighest; // สำหรับแสดง Badge "HIGHEST"

  const BidHistoryItem({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.amount,
    this.avatarUrl,
    this.isHighest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ถ้าเป็นผู้ประมูลสูงสุด ให้มีขอบสีม่วงอ่อนๆ
        color: isHighest ? const Color(0xFFF5F6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighest
            ? Border.all(color: const Color(0xFF6067ED).withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // 1. รูปโปรไฟล์ (CircleAvatar)
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),

          // 2. ชื่อและเวลา (Username & Time)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

          // 3. ยอดเงิน (Amount)
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
