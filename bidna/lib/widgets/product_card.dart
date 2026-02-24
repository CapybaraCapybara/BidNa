import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // อย่าลืม import สำหรับ Timestamp

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String productId;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.data,
    required this.productId,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Timer? _timer;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();

    // ดึงเวลาสิ้นสุดจากข้อมูล (รองรับทั้ง Timestamp จาก Firebase หรือ null)
    if (widget.data['endTime'] != null) {
      _endTime = (widget.data['endTime'] as Timestamp).toDate();
    } else {
      _endTime = DateTime.now(); // ถ้าไม่มีเวลาให้ถือว่าหมดเวลาแล้ว
    }

    // สร้าง Timer ให้อัปเดตตัวเองทุก 1 วินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // เช็คว่าถ้าเวลาหมดแล้ว ให้หยุด Timer ไปเลยเพื่อประหยัดทรัพยากร
        if (DateTime.now().isAfter(_endTime)) {
          _timer?.cancel();
        }
        setState(() {}); // สั่งให้วาดป้ายเวลาใหม่
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ทำลาย Timer ทิ้งเมื่อการ์ดนี้ถูกเลื่อนหายไปจากจอ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. จัดการรูปภาพ
    List images = widget.data['images'] ?? [];
    String? base64Image = images.isNotEmpty ? images[0] : null;

    // 2. จัดการข้อมูลพื้นฐาน
    double price = (widget.data['currentPrice'] ?? 0).toDouble();
    String title = widget.data['title'] ?? "No Name";
    int bids = widget.data['bids'] ?? 0;

    // 3. คำนวณเวลาและสถานะ
    Duration remaining = _endTime.difference(DateTime.now());
    bool isEnded = remaining.isNegative;
    bool isUrgent = remaining.inMinutes < 10 && !isEnded;

    // จัดรูปแบบข้อความและสีของป้าย
    String timeText;
    Color badgeColor;

    if (isEnded) {
      timeText = "Ended";
      badgeColor = Colors.grey.shade600;
    } else {
      int h = remaining.inHours;
      int m = remaining.inMinutes % 60;
      int s = remaining.inSeconds % 60;

      if (h > 0) {
        timeText = "${h}h ${m}m left"; // ถ้าเกิน 1 ชม. โชว์แค่ ชม. กับ นาที
      } else {
        timeText = "${m}m ${s}s left"; // ถ้าน้อยกว่า 1 ชม. โชว์นาที กับ วินาที
      }

      badgeColor = isUrgent
          ? Colors
                .redAccent // ใกล้หมดเวลา = สีแดง (Urgent)
          : const Color.fromRGBO(96, 103, 237, 1); // ปกติ = สีฟ้า
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: base64Image != null
                        ? Image.memory(
                            base64Decode(base64Image),
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            gaplessPlayback:
                                true, // กันรูปกระพริบเวลาการ์ดอัปเดต
                          )
                        : Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                  ),

                  // ปุ่ม Favorite
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border, size: 20),
                        color: Colors.grey,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        onPressed: () {},
                      ),
                    ),
                  ),

                  // ป้ายสถานะเวลา (อัปเดตแบบ Real-time)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            badgeColor, // ใช้สีที่เราคำนวณไว้ (เทา, แดง, หรือฟ้า)
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEnded
                                ? Icons.timer_off
                                : Icons.timer, // เปลี่ยนไอคอนตอนจบ
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeText, // ข้อความเวลาที่เราคำนวณไว้
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Current Bid",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '฿${price.toStringAsFixed(0)}', // เปลี่ยน $ เป็น ฿ ตามที่คุณใช้ก่อนหน้านี้
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(96, 103, 237, 1),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.gavel,
                          size: 14,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$bids bids",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8), // เว้นขอบล่างนิดหน่อยให้ดูสวยงาม
            ],
          ),
        ),
      ),
    );
  }
}
