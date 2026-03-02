import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bidna/widgets/bidPriceSelector.dart';
import 'package:bidna/widgets/countDownTimerCard.dart';
import 'package:bidna/widgets/bidHistoryItem.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

          User? currentUser = FirebaseAuth.instance.currentUser;

          // ดึงแค่ UID เป็น String
          String? myUid = currentUser?.uid;

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
                        currentPrice: (data['currentPrice'] ?? 0).toDouble(),
                        bidCount: 0,
                        onBidPlaced: (amount) async {
                          try {
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login to place a bid!'),
                                ),
                              );
                              return;
                            }

                            // อ้างอิง Product นี้
                            final productRef = FirebaseFirestore.instance
                                .collection('Products')
                                .doc(widget.productId);

                            // ---------------------------------------------------------
                            // 🌟 STEP 1: หาตัว "ผู้ชนะคนปัจจุบัน" (ก่อนที่เราจะประมูลทับ)
                            // ---------------------------------------------------------
                            final lastBidSnapshot = await productRef
                                .collection('bids')
                                .orderBy(
                                  'price',
                                  descending: true,
                                ) // เรียงจากราคาแพงสุด
                                .limit(1) // เอาแค่คนเดียวที่อยู่บนสุด
                                .get();

                            String? previousWinnerId;
                            if (lastBidSnapshot.docs.isNotEmpty) {
                              previousWinnerId = lastBidSnapshot
                                  .docs
                                  .first['userId']; // เก็บ UID ของคนนั้นไว้
                            }

                            // ---------------------------------------------------------
                            // 🌟 STEP 2: อัปเดตราคาใหม่ และเพิ่มประวัติของเรา (โค้ดเดิม)
                            // ---------------------------------------------------------
                            await productRef.update({
                              'currentPrice': amount,
                              'totalBids': FieldValue.increment(1),
                            });

                            await productRef.collection('bids').add({
                              'price': amount,
                              'timestamp': FieldValue.serverTimestamp(),
                              'userId': currentUser.uid,
                            });

                            // ---------------------------------------------------------
                            // 🌟 STEP 3: แจ้งเตือนคนโดนปาดหน้า (OUTBID)
                            // ---------------------------------------------------------
                            // เงื่อนไข: ต้องมีคนเคยประมูลไว้ก่อน (!= null) และ คนๆ นั้นต้อง "ไม่ใช่ตัวเราเอง"
                            if (previousWinnerId != null &&
                                previousWinnerId != currentUser.uid) {
                              // ยิงข้อมูลเข้าไปที่ Collection ย่อย notifications ของคนที่โดนปาด
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(
                                    previousWinnerId,
                                  ) // 👈 เล็งเป้าไปที่ UID ของคนที่โดนปาด
                                  .collection('notifications')
                                  .add({
                                    'title': 'You have been outbid! 😱',
                                    'message':
                                        'Someone placed a higher bid of ฿${amount.toStringAsFixed(0)} on your item.',
                                    'isRead': false, // ยังไม่ได้อ่าน
                                    'type': 'OUTBID',
                                    'productId': widget
                                        .productId, // ใส่ ID สินค้าไว้เผื่อกดเข้าไปดู
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                            }

                            // แสดงข้อความบนหน้าจอว่าประมูลสำเร็จ
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bid placed successfully! 🎉'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to place bid: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
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
                                padding: EdgeInsets.zero,
                                shrinkWrap:
                                    true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: bids.length,
                                itemBuilder: (context, index) {
                                  var bidData =
                                      bids[index].data()
                                          as Map<String, dynamic>;

                                  bool isHighest = index == 0;
                                  DateTime bidTime =
                                      (bidData['timestamp'] as Timestamp)
                                          .toDate();
                                  String userId = bidData['userId'] ?? "";

                                  // ช้ FutureBuilder ไปดึงข้อมูล User จาก ID
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection(
                                          'Users',
                                        ) 
                                        .doc(userId)
                                        .get(),
                                    builder: (context, userSnapshot) {
                                      // กำหนดชื่อเริ่มต้นระหว่างรอโหลด หรือหาไม่เจอ
                                      String displayName = "Loading...";

                                      // ถ้าโหลดข้อมูล User เสร็จแล้วและมีข้อมูลอยู่จริง
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (userSnapshot.hasData &&
                                            userSnapshot.data!.exists) {
                                          var userData =
                                              userSnapshot.data!.data()
                                                  as Map<String, dynamic>;
                                          displayName =
                                              userData['displayName'] ??
                                              "Anonymous";
                                        } else {
                                          displayName =
                                              "Unknown User"; // กรณีหา UID นี้ไม่เจอในระบบ
                                        }
                                      }

                                      return BidHistoryItem(
                                        username:
                                            displayName,
                                        timeAgo: "Just now",
                                        amount: (bidData['price'] ?? 0)
                                            .toDouble(),
                                        isHighest: isHighest,
                                      );
                                    },
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
