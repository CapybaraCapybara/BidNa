import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/widgets/product_card.dart'; // ดึง ProductCard ที่คุณมีอยู่แล้วมาใช้
import 'package:bidna/screens/product_details_page.dart';

class MyBidPage extends StatefulWidget {
  const MyBidPage({super.key});

  @override
  State<MyBidPage> createState() => _MyBidPageState();
}

class _MyBidPageState extends State<MyBidPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All'; // ค่าเริ่มต้นให้แสดงทั้งหมด (All, Open, Close)

  @override
  void initState() {
    super.initState();
    // สร้าง Tab จำนวน 2 หน้า
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
          // --- ตัวกรองสถานะ (All, Open, Close) ---
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

  // ฟังก์ชันสร้าง Grid สินค้า (ใช้ร่วมกันทั้ง 2 แท็บ)
  Widget _buildProductList({required bool isMyListing}) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("กรุณาเข้าสู่ระบบ"));
    }

    // สร้างเงื่อนไขในการค้นหา Firebase
    Query query = FirebaseFirestore.instance.collection('Products');
    
    if (isMyListing) {
      // กรณี: สินค้าที่ฉันลงขาย
      query = query.where('sellerUid', isEqualTo: user.uid);
    } else {
      // กรณี: รายการที่ฉันเคยเข้าไปประมูล (ค้นหา UID ใน Array 'bidders')
      query = query.where('bidders', arrayContains: user.uid);
    }

    return StreamBuilder<QuerySnapshot>(
      // เราดึงข้อมูลดิบมาก่อน แล้วค่อยมาจัดเรียง(Sort) และกรอง(Filter) ในเครื่อง 
      // เพื่อป้องกัน Error เรื่อง Composite Index ของ Firebase
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

        // 1. นำมากรองสถานะ (Open / Close) ตาม Dropdown ที่เลือก
        if (_selectedStatus != 'All') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'open').toString().toLowerCase();
            return status == _selectedStatus.toLowerCase();
          }).toList();
        }

        // 2. จัดเรียงเวลาจากใหม่สุด ไปเก่าสุด (เทียบจาก startTime)
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

        // 3. แสดงผลเป็น GridView เหมือนหน้า Home
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String docId = doc.id;

            return ProductCard(
              data: data,
              productId: docId,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailsPage(productId: docId)),
                );
              },
            );
          },
        );
      },
    );
  }
}