import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bidna/widgets/bidPriceSelector.dart';
import 'package:bidna/widgets/countDownTimerCard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/screens/chat_screens.dart'; // แก้เป็น chat_screen.dart ให้ตรงกับไฟล์ที่สร้าง
import 'package:intl/intl.dart'; // สำหรับจัด Format ตัวเลขและวันที่

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var data = snapshot.data!.data() as Map<String, dynamic>;
          List images = data['images'] ?? [];
          DateTime endTime = (data['endTime'] as Timestamp).toDate();

          User? currentUser = FirebaseAuth.instance.currentUser;
          String? myUid = currentUser?.uid;

          String sellerUid = data['sellerUid'] ?? '';
          String fallbackSellerName = data['sellerId'] ?? "Unknown Seller";

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
                      AuctionCountdownCard(endTime: endTime),
                      const SizedBox(height: 15),
                      
                      /* --- ส่วนลงประมูล --- */
                      (myUid != null && sellerUid.isNotEmpty && myUid == sellerUid)
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.lock_outline, color: Colors.grey, size: 32),
                                  SizedBox(height: 8),
                                  Text(
                                    "นี่คือสินค้าของคุณ คุณไม่สามารถประมูลได้",
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          : BidActionCard(
                              currentPrice: (data['currentPrice'] ?? 0).toDouble(),
                              bidCount: 0,
                              onBidPlaced: (amount) async {
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please login to place a bid!')),
                                  );
                                  return;
                                }

                                // ตรวจสอบราคาประมูลว่าน้อยกว่าหรือเท่ากับราคาปัจจุบันหรือไม่
                                double currentHighestPrice = (data['currentPrice'] ?? 0).toDouble();
                                if (amount <= currentHighestPrice) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('กรุณาใส่ราคาที่มากกว่าราคาปัจจุบัน!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return; // หยุดการทำงาน ไม่ส่งข้อมูลขึ้นฐานข้อมูล
                                }

                                try {
                                  final productRef = FirebaseFirestore.instance
                                      .collection('Products')
                                      .doc(widget.productId);

                                  // ---------------------------------------------------------
                                  // 🌟 STEP 1: หาตัว "ผู้ชนะคนปัจจุบัน" (ก่อนที่เราจะประมูลทับ)
                                  // ---------------------------------------------------------
                                  final lastBidSnapshot = await productRef
                                      .collection('bids')
                                      .orderBy('price', descending: true) // เรียงจากราคาแพงสุด
                                      .limit(1) // เอาแค่คนเดียวที่อยู่บนสุด
                                      .get();

                                  String? previousWinnerId;
                                  if (lastBidSnapshot.docs.isNotEmpty) {
                                    previousWinnerId = lastBidSnapshot.docs.first['userId']; // เก็บ UID ของคนนั้นไว้
                                  }

                                  // ---------------------------------------------------------
                                  // 🌟 STEP 2: อัปเดตราคาใหม่ และเพิ่มประวัติของเรา
                                  // ---------------------------------------------------------
                                  await productRef.update({
                                    'currentPrice': amount,
                                    'totalBids': FieldValue.increment(1), 
                                    'bidders': FieldValue.arrayUnion([myUid]), 
                                    
                                    // [เพิ่มบรรทัดนี้] จำ UID ของคนที่ให้ราคาสูงสุด ณ ปัจจุบัน
                                    'highestBidderUid': myUid, 
                                  });

                                  await productRef.collection('bids').add({
                                    'price': amount,
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'userId': myUid ?? "unknown_user", 
                                  });

                                  // ---------------------------------------------------------
                                  // 🌟 STEP 3: แจ้งเตือนคนโดนปาดหน้า (OUTBID)
                                  // ---------------------------------------------------------
                                  // เงื่อนไข: ต้องมีคนเคยประมูลไว้ก่อน (!= null) และ คนๆ นั้นต้อง "ไม่ใช่ตัวเราเอง"
                                  if (previousWinnerId != null && previousWinnerId != currentUser.uid) {
                                    await FirebaseFirestore.instance
                                        .collection('Users')
                                        .doc(previousWinnerId) // เล็งเป้าไปที่ UID ของคนที่โดนปาด
                                        .collection('notifications')
                                        .add({
                                      'title': 'You have been outbid! 😱',
                                      'message': 'Someone placed a higher bid of ฿${amount.toStringAsFixed(0)} on your item.',
                                      'isRead': false, 
                                      'type': 'OUTBID',
                                      'productId': widget.productId, 
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Bid placed successfully! 🎉'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
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
                      
                      /* --- ส่วนผู้สร้างประมูล --- */
                      FutureBuilder<DocumentSnapshot>(
                        future: sellerUid.isNotEmpty 
                            ? FirebaseFirestore.instance.collection('Users').doc(sellerUid).get() 
                            : null,
                        builder: (context, userSnapshot) {
                          String displaySellerName = fallbackSellerName;
                          String? profileImageBase64;

                          if (userSnapshot.connectionState == ConnectionState.done && 
                              userSnapshot.hasData && 
                              userSnapshot.data!.exists) {
                            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            displaySellerName = userData['displayName'] ?? fallbackSellerName;
                            profileImageBase64 = userData['profileImage'];
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
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
                                          backgroundImage: (profileImageBase64 != null && profileImageBase64.isNotEmpty)
                                              ? MemoryImage(base64Decode(profileImageBase64))
                                              : null,
                                          child: (profileImageBase64 == null || profileImageBase64.isEmpty)
                                              ? const Icon(Icons.person, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displaySellerName,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                                Text(
                                                  '${data['sellerRating'] ?? "N/A"} • ${data['sellerSales'] ?? "0"} sales',
                                                  style: const TextStyle(color: Colors.grey),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    // 🟢 ปุ่ม Chat ที่อัปเดตแล้ว
                                    OutlinedButton(
                                      onPressed: () {
                                        if (currentUser == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("กรุณาเข้าสู่ระบบเพื่อแชท")),
                                          );
                                          return;
                                        }
                                        if (myUid == sellerUid) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("คุณไม่สามารถแชทกับตัวเองได้")),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              peerId: sellerUid,
                                              peerName: displaySellerName,
                                              peerAvatarBase64: profileImageBase64,
                                            ),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.grey, width: 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text("Chat", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "Description",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['description'] ?? "",
                        style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      
                      /* --- ประวัติการประมูล --- */
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bid History",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Products')
                                .doc(widget.productId)
                                .collection('bids')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Text("No bids yet. Be the first!", style: TextStyle(color: Colors.grey));
                              }

                              final bids = snapshot.data!.docs;

                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bids.length,
                                itemBuilder: (context, index) {
                                  var bidData = bids[index].data() as Map<String, dynamic>;
                                  bool isHighest = index == 0;
                                  String bidderUid = bidData['userId'] ?? "";
                                  double amount = (bidData['price'] ?? 0).toDouble();
                                  
                                  // แปลงเวลา
                                  Timestamp? ts = bidData['timestamp'] as Timestamp?;
                                  String timeAgo = ts != null 
                                      ? DateFormat('dd MMM, HH:mm').format(ts.toDate()) 
                                      : "Just now";

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: bidderUid.isNotEmpty 
                                        ? FirebaseFirestore.instance.collection('Users').doc(bidderUid).get() 
                                        : null,
                                    builder: (context, userSnapshot) {
                                      String displayName = "Anonymous";
                                      String? profileImageBase64;

                                      if (userSnapshot.connectionState == ConnectionState.done && 
                                          userSnapshot.hasData && 
                                          userSnapshot.data!.exists) {
                                        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                        displayName = userData['displayName'] ?? "Anonymous";
                                        profileImageBase64 = userData['profileImage'];
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isHighest ? const Color(0xFF6347EB).withOpacity(0.05) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isHighest ? const Color(0xFF6347EB).withOpacity(0.3) : Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.grey.shade200,
                                              backgroundImage: (profileImageBase64 != null && profileImageBase64.isNotEmpty)
                                                  ? MemoryImage(base64Decode(profileImageBase64))
                                                  : null,
                                              child: (profileImageBase64 == null || profileImageBase64.isEmpty)
                                                  ? const Icon(Icons.person, color: Colors.grey)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: isHighest ? const Color(0xFF6347EB) : Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    timeAgo,
                                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "฿${NumberFormat('#,###').format(amount)}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isHighest ? const Color(0xFF6347EB) : Colors.black87,
                                                  ),
                                                ),
                                                if (isHighest)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF6347EB),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text(
                                                      "Highest",
                                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
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