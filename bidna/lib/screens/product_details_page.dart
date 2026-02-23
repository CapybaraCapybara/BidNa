import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bidna/widgets/bidPriceSelector.dart';
import 'package:bidna/widgets/countDownTimerCard.dart';
import 'package:bidna/widgets/bidHistoryItem.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Products')
            .doc(widget.productId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          List images = data['images'] ?? [];
          DateTime endTime = (data['endTime'] as Timestamp).toDate();
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  SizedBox(
                    height: 400,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (_, i) => Image.memory(
                        base64Decode(images[i]),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['category'] ?? "",
                        style: const TextStyle(
                          color: Color(0xFF6347EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data['title'] ?? "",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      /* ส่วนเวลานับ */
                      AuctionCountdownCard(endTime: endTime),
                      const SizedBox(height: 15),
                      /* ส่วนลงประมูล */
                      BidActionCard(
                        currentPrice: data['currentPrice'],
                        bidCount: 0,
                        onBidPlaced: (amount) {},
                        endTime: endTime,
                      ),
                      const SizedBox(height: 20),
                      /* ส่วนผู้สร้างประมูล */
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ), // สีพื้นหลังฟ้าอ่อนตามรูป
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.05,
                              ), // สีของเงา (แนะนำให้ใช้สีดำจางๆ)
                              spreadRadius: 1, // การขยายตัวของเงา
                              blurRadius: 10, // ความฟุ้งของเงา (ยิ่งมากยิ่งนวล)
                              offset: const Offset(
                                0,
                                4,
                              ), // ระยะเยื้องของเงา (x, y) ในที่นี้คือเยื้องลงล่าง 4 unit
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[300],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['sellerId'] ?? "Unknown Seller",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            Text(
                                              '${data['sellerRating'] ?? "N/A"} • ${data['sellerSales'] ?? "0"} sales',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Chat",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['description'] ?? "",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bid History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ตัวอย่างการเรียกใช้ Widget ที่เราสร้าง
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Products')
                                .doc(
                                  widget.productId,
                                ) // อ้างอิง ID ของสินค้าหน้านี้
                                .collection(
                                  'bids',
                                ) // เข้าไปที่ Subcollection 'bids'
                                .orderBy(
                                  'timestamp',
                                  descending: true,
                                ) // สำคัญ: เรียงจากเวลาล่าสุด (หรือราคาแพงสุด) ขึ้นก่อน
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Text(
                                  "No bids yet. Be the first!",
                                  style: TextStyle(color: Colors.grey),
                                );
                              }

                             
                              final bids = snapshot.data!.docs;

                              return ListView.builder(
                                shrinkWrap:
                                    true, // สำคัญมาก! ต้องใส่เมื่อ ListView อยู่ใน Column หรือ SingleChildScrollView
                                physics:
                                    const NeverScrollableScrollPhysics(), // ป้องกันไม่ให้มัน Scroll แย่งกับ SingleChildScrollView ตัวแม่
                                itemCount: bids.length, // จำนวนรายการทั้งหมด
                                itemBuilder: (context, index) {
                                  // ดึงข้อมูลแต่ละแถวออกมาตาม index
                                  var bidData =
                                      bids[index].data()
                                          as Map<String, dynamic>;

                                  // ถ้าเราเรียงจากแพงสุด->ถูกสุด หรือ ล่าสุด->เก่าสุด แล้ว
                                  // อันดับแรกสุด (index == 0) ก็คือ Highest Bid เสมอครับ!
                                  bool isHighest = index == 0;

                                  // แปลง Timestamp จาก Firebase กลับเป็น DateTime
                                  DateTime bidTime =
                                      (bidData['timestamp'] as Timestamp)
                                          .toDate();

                                  return BidHistoryItem(
                                    username:
                                        bidData['userId'] ??
                                        "Anonymous", // ดึงชื่อจาก Firebase
                                    timeAgo:
                                        "Just now", // ใส่ Hardcode ไว้ก่อนเดี๋ยวมาแก้
                                    amount: (bidData['price'] ?? 0)
                                        .toDouble(), // ดึงราคาจาก Firebase
                                    isHighest:
                                        isHighest, // ส่งค่า true เฉพาะบรรทัดแรก
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
