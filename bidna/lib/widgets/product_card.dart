import 'dart:convert';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  // รับข้อมูลดิบ (Map) และ ID แทนการใช้ Model Class
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
  Widget build(BuildContext context) {
    // ดึงรูปภาพ (เช็คว่ามีรูปใน list ไหม)
    List images = data['images'] ?? [];
    String? base64Image = images.isNotEmpty ? images[0] : null;

    // ดึงราคา
    double price = (data['currentPrice'] ?? 0).toDouble();
    // ดึงชื่อ
    String title = data['title'] ?? "No Name";
    // ดึงจำนวน bid (ถ้าไม่มีให้เป็น 0)
    int bids = data['bids'] ?? 0;

    return GestureDetector(
      onTap: onTap,
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
                            base64Decode(base64Image), // แปลง Base64 เป็นรูป
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey),
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

                  // เวลานับถอยหลัง (สมมติแสดงไว้ก่อน)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.timer, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "Ending Soon", 
                            style: TextStyle(
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
                        const Text(
                          "Current Bid",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${price.toStringAsFixed(0)}',
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
                        const Icon(Icons.gavel, size: 14, color: Colors.black45),
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
            ],
          ),
        ),
      ),
    );
  }
}