import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // ดึงเวลาสิ้นสุดจากข้อมูล
    if (widget.data['endTime'] != null) {
      _endTime = (widget.data['endTime'] as Timestamp).toDate();
    } else {
      _endTime = DateTime.now();
    }

    // อัปเดต UI ทุกวินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (DateTime.now().isAfter(_endTime)) {
          _timer?.cancel();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List images = widget.data['images'] ?? [];
    String? base64Image = images.isNotEmpty ? images[0] : null;

    double price = (widget.data['currentPrice'] ?? 0).toDouble();
    String title = widget.data['title'] ?? "No Name";

    Duration remaining = _endTime.difference(DateTime.now());
    bool isEnded = remaining.isNegative;
    bool isUrgent = remaining.inMinutes < 10 && !isEnded;

    // ค้นหาและแทนที่ส่วนการคำนวณ timeText ใน build method ของ product_card.dart

    String timeText;
    Color badgeColor;

    if (isEnded) {
      timeText = "Ended";
      badgeColor = Colors.grey.shade600;
    } else {
      // คำนวณส่วนต่างแบบแยกหน่วย
      int days = remaining.inDays;
      int hours = remaining.inHours % 24;
      int minutes = remaining.inMinutes % 60;
      int seconds = remaining.inSeconds % 60;

      if (days >= 1) {
        // กรณีเกิน 24 ชม.: แสดง วัน และ ชั่วโมง
        timeText = "${days}d ${hours}h left";
      } else if (remaining.inHours >= 1) {
        // กรณีไม่ถึงวันแต่เกิน 1 ชม.: แสดง ชั่วโมง และ นาที
        timeText = "${hours}h ${minutes}m left";
      } else {
        // กรณีไม่ถึง 1 ชม.: แสดง นาที และ วินาที
        timeText = "${minutes}m ${seconds}s left";
      }

      badgeColor = isUrgent ? Colors.redAccent : const Color.fromRGBO(96, 103, 237, 1);
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: base64Image != null
                        ? Image.memory(
                            base64Decode(base64Image),
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                  ),
                  // ป้ายเวลาคงเหลือ
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isEnded ? Icons.timer_off : Icons.timer, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        const Text("Current Bid", style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          '฿${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(96, 103, 237, 1),
                          ),
                        ),
                      ],
                    ),
                    // ส่วนแสดงจำนวน Bids จริงจาก Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Products')
                          .doc(widget.productId)
                          .collection('bids')
                          .snapshots(),
                      builder: (context, snapshot) {
                        int bidCount = 0;
                        if (snapshot.hasData) {
                          bidCount = snapshot.data!.docs.length;
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.gavel, size: 14, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(
                              "$bidCount bids",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}