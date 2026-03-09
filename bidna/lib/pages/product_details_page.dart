import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:bidna/widgets/bidPriceSelector.dart';
import 'package:bidna/widgets/countDownTimerCard.dart';
import 'package:bidna/widgets/auction_result_cards.dart';
import 'package:bidna/pages/user_profile_view_page.dart';
import 'package:bidna/pages/write_review_page.dart';
import 'package:bidna/widgets/seller_info_card.dart';
import 'package:bidna/widgets/bid_history_item.dart';
import 'package:bidna/services/user_service.dart';

// 🔴 Import Models & Services
import 'package:bidna/models/product_model.dart';
import 'package:bidna/services/product_service.dart';
import 'package:bidna/services/review_service.dart';
import 'package:bidna/services/auth_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService =
      ProductService(); // 🔴 เรียกใช้ Service สำหรับการประมูล
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

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
        stream: _productService.getProductStream(widget.productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔴 แปลงเป็น ProductModel
          ProductModel product = ProductModel.fromDoc(snapshot.data!);

          User? currentUser = _authService.getCurrentUser();
          String? myUid = _authService.getCurrentUserId();

          // ถ้าไม่มี UID เจ้าของ ให้ Fallback
          String sellerUid = product.sellerUid;

          DateTime now = DateTime.now();
          bool isAuctionEnded = now.isAfter(product.endTime);

          // 2. เช็คว่าเราคือผู้ชนะไหม
          bool amIWinner = (myUid != null && myUid == product.highestBidderUid);

          String productStatus = product.status;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.images.isNotEmpty)
                  SizedBox(
                    height: 400,
                    child: PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (_, i) => Image.memory(
                        base64Decode(product.images[i]),
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
                        product.category,
                        style: const TextStyle(
                          color: Color(0xFF6347EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      AuctionCountdownCard(
                        endTime: product.endTime,
                        onTimerEnded: () {
                          // สั่งให้หน้าหลักรีเฟรชตัวเอง 1 รอบ เพื่อเช็คกล่องผู้ชนะ
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(height: 15),

                      // กรณีที่ 1: สถานะเป็น 'COMPLETED' (จบงานสมบูรณ์แบบแล้ว)
                      if (productStatus == 'COMPLETED' && amIWinner)
                        const OrderCompletedCard()
                      // กรณีที่ 2: สถานะเป็น 'PAID' และเราคือผู้ชนะ (ต้องโชว์ปุ่มรอรับของ)
                      else if (productStatus == 'PAID' && amIWinner)
                        ConfirmReceiptCard(
                          onConfirmPressed: () async {
                            // กดเพื่อโอนเงินให้คนขาย
                            try {
                              await _productService.confirmItemReceipt(
                                productId: widget.productId,
                                sellerUid: sellerUid,
                                amount: product.currentPrice,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'ยืนยันรับสินค้าสำเร็จ! ผู้ขายได้รับเงินแล้ว 🎉',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('เกิดข้อผิดพลาด: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        )
                      // กรณีที่ 3: สถานะเป็น 'PAID' แต่เราไม่ใช่ผู้ชนะ (คนอื่นมองเห็น)
                      else if (productStatus == 'PAID' ||
                          (isAuctionEnded && !amIWinner))
                        const EndedActionCard()
                      else if (isAuctionEnded && amIWinner)
                        WinnerActionCard(
                          winningPrice: product.currentPrice,
                          onPayPressed: () {

                            // 🌟 แสดง Pop-up ยืนยันการชำระเงิน
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "ยืนยันการชำระเงิน",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  "ระบบจะทำการหัก Coupon จำนวน ${NumberFormat('#,###').format(product.currentPrice)} ออกจากบัญชีของคุณ\n\n"
                                  "⚠️ สำคัญ: เมื่อคุณได้รับสินค้าแล้ว กรุณากลับมากดปุ่ม 'ฉันได้รับสินค้าแล้ว' เพื่อปิดออเดอร์และโอน Coupon ให้กับผู้ขาย",
                                  style: const TextStyle(height: 1.5),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text(
                                      "ยกเลิก",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(
                                        dialogContext,
                                      ); // ปิด Pop-up ก่อน

                                      // รันฟังก์ชันหักเงิน
                                      try {
                                        await _productService.payForWonAuction(
                                          productId: widget.productId,
                                          winnerUid: myUid,
                                          amount: product.currentPrice,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'ชำระเงินสำเร็จ! 🎉',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text(
                                      "ตกลง",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else if (isAuctionEnded)
                        const EndedActionCard()
                      else if (myUid != null &&
                          sellerUid.isNotEmpty &&
                          myUid == sellerUid)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "นี่คือสินค้าของคุณ คุณไม่สามารถประมูลได้",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      /* --- ส่วนลงประมูล --- */
                      else
                        BidActionCard(
                          currentPrice: product.currentPrice,
                          bidCount: product.totalBids,
                          minBidIncrement: product.minBidIncrement,
                          endTime: product.endTime,
                          onBidPlaced: (amount) async {
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login to place a bid!'),
                                ),
                              );
                              return;
                            }

                            if (amount <= product.currentPrice) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'กรุณาใส่ราคาที่มากกว่าราคาปัจจุบัน!',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (amount <
                                product.currentPrice +
                                    product.minBidIncrement) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'กรุณาเพิ่มราคาขั้นต่ำ ฿${product.minBidIncrement.toStringAsFixed(0)}',
                                  ),
                                  backgroundColor: Colors.orange.shade700,
                                ),
                              );
                              return;
                            }

                            try {
                              // 🔴 เรียกใช้ Service แทนการเขียน Update และ Add ซับซ้อนใน UI
                              await _productService.placeBid(
                                productId: widget.productId,
                                myUid: myUid!,
                                amount: amount,
                                previousWinnerId: product.highestBidderUid,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Bid placed successfully! 🎉',
                                    ),
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
                        ),
                      const SizedBox(height: 20),

                      /* --- ส่วนผู้สร้างประมูล --- */
                      SellerInfoCard(
                        sellerUid: sellerUid,
                        currentUserUid: myUid,
                        userService: _userService,
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
                          product.description.trim().isEmpty ? "No description" : product.description,
                          style: TextStyle(
                            color: product.description.trim().isEmpty ? Colors.grey.shade500 : Colors.grey.shade700,
                            fontStyle: product.description.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                      /* --- ประวัติการประมูล --- */
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
                          StreamBuilder<QuerySnapshot>(
                            stream: _productService.getBidHistoryStream(
                              widget.productId,
                            ),
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
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bids.length,
                                itemBuilder: (context, index) {
                                  var bidData =
                                      bids[index].data()
                                          as Map<String, dynamic>;
                                  bool isHighest = index == 0;
                                  String bidderUid = bidData['userId'] ?? "";
                                  double amount = (bidData['price'] ?? 0)
                                      .toDouble();
                                  Timestamp? ts =
                                      bidData['timestamp'] as Timestamp?;
                                  String timeAgo = ts != null
                                      ? DateFormat(
                                          'dd MMM, HH:mm',
                                        ).format(ts.toDate())
                                      : "Just now";

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: bidderUid.isNotEmpty
                                        ? _productService.getUserData(bidderUid)
                                        : null,
                                    builder: (context, userSnapshot) {
                                      String displayName = "Anonymous";
                                      String? profileImageBase64;

                                      if (userSnapshot.connectionState ==
                                              ConnectionState.done &&
                                          userSnapshot.hasData &&
                                          userSnapshot.data!.exists) {
                                        var userData =
                                            userSnapshot.data!.data()
                                                as Map<String, dynamic>;
                                        displayName =
                                            userData['displayName'] ??
                                            "Anonymous";
                                        profileImageBase64 =
                                            userData['profileImage'];
                                      }

                                      // 🌟 ลบโค้ดวาด UI ของเดิมทิ้ง แล้วเรียกใช้ Widget ตัวนี้แทน!
                                      // ครอบด้วย GestureDetector เพื่อให้กดไปดู Profile ได้เหมือนเดิม
                                      return GestureDetector(
                                        onTap: () {
                                          if (bidderUid.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    UserProfileViewPage(
                                                      targetUserId: bidderUid,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        child: BidHistoryItem(
                                          username: displayName,
                                          timeAgo: timeAgo,
                                          amount: amount,
                                          profileImageBase64:
                                              profileImageBase64,
                                          isHighest: isHighest,
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

                      // ── ปุ่ม Write Review ──
                      Builder(
                        builder: (_) {
                          final bool isAuctionEnded = DateTime.now().isAfter(
                            product.endTime,
                          );
                          final bool isWinner =
                              isAuctionEnded &&
                              myUid != null &&
                              product.highestBidderUid == myUid &&
                              myUid != sellerUid;
                          final bool isAlreadyReviewed =
                              product.isReviewed && product.reviewedBy == myUid;

                          if (!isWinner) return const SizedBox.shrink();

                          if (!isAlreadyReviewed) {
                            _reviewService.notifyWinnerToReview(
                              winnerId: myUid,
                              productId: widget.productId,
                              productTitle: product.title,
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: isAlreadyReviewed
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'คุณได้ review สินค้านี้แล้ว',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => WriteReviewPage(
                                              productId: widget.productId,
                                              productTitle: product.title,
                                              sellerId: sellerUid,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.rate_review_outlined,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Write a Review',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6347EB,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                          );
                        },
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
