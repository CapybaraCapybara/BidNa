import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/widgets/product_card.dart';
import 'package:bidna/screens/product_details_page.dart';

class MyBidPage extends StatefulWidget {
  const MyBidPage({super.key});

  @override
  State<MyBidPage> createState() => _MyBidPageState();
}

class _MyBidPageState extends State<MyBidPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All'; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(238, 237, 237, 1),
      appBar: AppBar(
        title: const Text("My Bids & Listings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                icon: const Icon(Icons.filter_list, color: Color(0xFF6347EB)),
                style: const TextStyle(color: Color(0xFF6347EB), fontWeight: FontWeight.bold),
                items: ['All', 'Open', 'Close'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6347EB),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6347EB),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "รายการที่ฉันประมูล"),
            Tab(text: "สินค้าที่ฉันลงขาย"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // แท็บที่ 1: ของที่ฉันไปประมูล
          _buildProductList(isMyListing: false),
          // แท็บที่ 2: ของที่ฉันลงขาย
          _buildProductList(isMyListing: true),
        ],
      ),
    );
  }

  Widget _buildProductList({required bool isMyListing}) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("กรุณาเข้าสู่ระบบ"));
    }

    Query query = FirebaseFirestore.instance.collection('Products');
    
    if (isMyListing) {
      query = query.where('sellerUid', isEqualTo: user.uid);
    } else {
      query = query.where('bidders', arrayContains: user.uid);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isMyListing ? "คุณยังไม่มีสินค้าที่ลงขาย" : "คุณยังไม่เคยประมูลสินค้า",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        var docs = snapshot.data!.docs;

        // 1. กรองสถานะ
        if (_selectedStatus != 'All') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'open').toString().toLowerCase();
            return status == _selectedStatus.toLowerCase();
          }).toList();
        }

        // 2. เรียงเวลา
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          Timestamp aTime = aData['startTime'] ?? Timestamp.now();
          Timestamp bTime = bData['startTime'] ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "ไม่มีสินค้าในสถานะ '$_selectedStatus'",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        // --- 3. ตรวจสอบว่าเป็นการแสดงผลแท็บไหน ---
        if (isMyListing) {
          // แท็บ 2 (ฉันลงขาย): แสดง Grid ธรรมดา
          return _buildGridView(docs);
        } else {
          // แท็บ 1 (ฉันประมูล): แยกสินค้าเป็น 2 กอง (นำอยู่ vs โดนแซง)
          List<DocumentSnapshot> leadingDocs = [];
          List<DocumentSnapshot> outbidDocs = [];

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['highestBidderUid'] == user.uid) {
              leadingDocs.add(doc);
            } else {
              outbidDocs.add(doc);
            }
          }

          // แสดงผลแบบแยกหัวข้อ
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leadingDocs.isNotEmpty) ...[
                  _buildSectionHeader("👑 สินค้าที่กำลังนำอยู่ (Leading)", Colors.green.shade600),
                  _buildGridView(leadingDocs),
                ],
                if (outbidDocs.isNotEmpty) ...[
                  _buildSectionHeader("⚠️ สินค้าที่โดนแซงแล้ว (Outbid)", Colors.redAccent),
                  _buildGridView(outbidDocs),
                ],
                if (leadingDocs.isEmpty && outbidDocs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Text("ไม่มีข้อมูล", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                const SizedBox(height: 30), // เว้นระยะล่างสุด
              ],
            ),
          );
        }
      },
    );
  }

  // --- Widget ตัวช่วยสำหรับสร้างหัวข้อ ---
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // --- Widget ตัวช่วยสำหรับสร้าง GridView ของสินค้า ---
  Widget _buildGridView(List<DocumentSnapshot> docsList) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shrinkWrap: true, // สำคัญมาก เพื่อให้เลื่อนไปพร้อมกับ SingleChildScrollView ได้
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: docsList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final doc = docsList[index];
        final data = doc.data() as Map<String, dynamic>;
        return ProductCard(
          data: data,
          productId: doc.id,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailsPage(productId: doc.id)),
            );
          },
        );
      },
    );
  }
}