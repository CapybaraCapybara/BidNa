import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 🔴 Import Model
import 'package:bidna/models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // 🔴 แยกฟังก์ชันสร้าง Timer ออกมา เพื่อให้เรียกซ้ำได้
  void _startTimer() {
    _timer?.cancel(); // เคลียร์ Timer ตัวเก่าทิ้งก่อน
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // ใช้เวลาจาก widget.product.endTime โดยตรง
        if (DateTime.now().isAfter(widget.product.endTime)) {
          _timer?.cancel();
        }
        setState(() {});
      }
    });
  }

  // 🔴 หัวใจสำคัญ: เมื่อ GridView รีไซเคิล Widget เอาของชิ้นใหม่มาใส่ ต้องเช็คและอัปเดต Timer
  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id || 
        oldWidget.product.endTime != widget.product.endTime) {
      _startTimer(); // ถ้ารหัสสินค้าเปลี่ยน หรือเวลาเปลี่ยน ให้เริ่มนับใหม่
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 ดึงค่าจาก widget.product สดๆ เสมอ
    String? base64Image = widget.product.images.isNotEmpty ? widget.product.images[0] : null;
    double price = widget.product.currentPrice;
    String title = widget.product.title;

    Duration remaining = widget.product.endTime.difference(DateTime.now());
    bool isEnded = remaining.isNegative;
    bool isUrgent = remaining.inMinutes < 10 && !isEnded;

    String timeText;
    Color badgeColor;

    if (isEnded) {
      timeText = "Ended";
      badgeColor = Colors.grey.shade600;
    } else {
      int days = remaining.inDays;
      int hours = remaining.inHours % 24;
      int minutes = remaining.inMinutes % 60;
      int seconds = remaining.inSeconds % 60;

      if (days >= 1) {
        timeText = "${days}d ${hours}h left";
      } else if (remaining.inHours >= 1) {
        timeText = "${hours}h ${minutes}m left";
      } else {
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
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Products')
                          .doc(widget.product.id)
                          .collection('bids')
                          .snapshots(),
                      builder: (context, snapshot) {
                        int bidCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
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