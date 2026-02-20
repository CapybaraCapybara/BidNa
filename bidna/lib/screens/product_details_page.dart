import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  ProductDetailsPage({required this.productId});

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
            .doc(productId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          List images = data['images'] ?? [];
          DateTime endTime = (data['endTime'] as Timestamp).toDate();

          Duration remainingTime = endTime.difference(DateTime.now());

          if (remainingTime.isNegative) {
            remainingTime = Duration.zero;
          }

          String hours = remainingTime.inHours.toString().padLeft(2, '0');
          String minutes = (remainingTime.inMinutes % 60).toString().padLeft(
            2,
            '0',
          );
          String seconds = (remainingTime.inSeconds % 60).toString().padLeft(
            2,
            '0',
          );

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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF0F5F9,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: Color(0xFF5E6E82),
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            _buildTimeColumn(hours, "H"),
                            _buildDivider(),
                            _buildTimeColumn(minutes, "M"),
                            _buildDivider(),
                            _buildTimeColumn(seconds, "S"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF0F5F9,
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
                                _info(
                                  "Current Bid",
                                  "฿${NumberFormat('#,###').format(data['currentPrice'])}",
                                ),
                                Text(
                                  '${data['bidCount'] ?? 0} Bids',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              // เมื่อใช้ Expanded แล้ว mainAxisAlignment จะไม่มีผลมากนัก เพราะปุ่มจะถูกยืดจนเต็มอยู่แล้ว
                              children: [
                                Expanded(
                                  child: OutlinedButton(
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
                                    child: Text(
                                      "฿${NumberFormat('#,###').format(data['currentPrice'] + 50)}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // เพิ่มช่องว่างระหว่างปุ่มเล็กน้อย
                                Expanded(
                                  child: OutlinedButton(
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
                                    child: Text(
                                      "฿${NumberFormat('#,###').format(data['currentPrice'] + 100)}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // เพิ่มช่องว่างระหว่างปุ่มเล็กน้อย
                                Expanded(
                                  child: OutlinedButton(
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
                                    child: Text(
                                      "฿${NumberFormat('#,###').format(data['currentPrice'] + 150)}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 1. ครอบ TextField ด้วย Expanded เพื่อให้มันใช้พื้นที่ที่เหลือในแนวราบ
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Enter your bid",
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.grey,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ), // เพิ่มระยะห่างระหว่างช่องกรอกกับปุ่ม
                                // 2. ปุ่มด้านขวาจะถูกดันไปจนสุดเพราะ TextField ขยายกินพื้นที่ที่เหลือ
                                ElevatedButton(
                                  onPressed: () {
                                    // ใส่ Logic การยื่นประมูลที่นี่
                                    print("Bid Placed!");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromRGBO(
                                      96,
                                      103,
                                      237,
                                      1,
                                    ), // สีม่วงตามธีมแอปคุณ
                                    foregroundColor: Colors.white, // สีตัวอักษร
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ), // ความโค้งมนของปุ่ม
                                    ),
                                    elevation: 2, // เงาของปุ่มให้ดูมีมิติ
                                  ),
                                  child: const Text(
                                    "Place Bid",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Minimum bid: ฿${NumberFormat('#,###').format(data['currentPrice'] + 50)}',
                                  style: TextStyle(color: Colors.grey),
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
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6347EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Place a Bid",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

  Widget _info(String l, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(
        v,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6347EB),
        ),
      ),
    ],
  );

  Widget _buildTimeColumn(String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF001737),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  // ฟังก์ชันสร้างเครื่องหมาย :
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        4,
        0,
        4,
        12,
      ), // ดันขึ้นเล็กน้อยให้ตรงกลางตัวเลข
      child: Text(
        ":",
        style: TextStyle(
          color: Color(0xFF001737),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
