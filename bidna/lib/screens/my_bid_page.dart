import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/widgets/product_card.dart';
import 'package:bidna/screens/product_details_page.dart';
import 'package:bidna/widgets/custom_app_bar.dart'; // อย่าลืม import CustomAppBar

class MyBidPage extends StatefulWidget {
  const MyBidPage({super.key});

  @override
  State<MyBidPage> createState() => _MyBidPageState();
}

class _MyBidPageState extends State<MyBidPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // ตัวกรองย่อยสำหรับแต่ละแท็บ
  String _bidFilter = 'All'; // All, Ongoing, Ended
  String _listingFilter = 'All'; // All, Ongoing, Ended

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

  // ฟังก์ชันเช็คว่าประมูลจบหรือยัง (ดูจาก status หรือ เวลา)
  bool _isAuctionEnded(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'open').toString().toLowerCase();
    if (status == 'close' || status == 'closed') return true;
    
    Timestamp? endTimeTs = data['endTime'];
    if (endTimeTs != null && endTimeTs.toDate().isBefore(DateTime.now())) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(238, 237, 237, 1),
      // 1. ใช้ CustomAppBar
      appBar: CustomAppBar(
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
          _buildBidsTab(),
          // แท็บที่ 2: ของที่ฉันลงขาย
          _buildListingsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // แท็บ 1: รายการที่ฉันประมูล (My Bids)
  // ==========================================
  Widget _buildBidsTab() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("กรุณาเข้าสู่ระบบ"));

    return Column(
      children: [
        _buildFilterChips(
          currentFilter: _bidFilter,
          onSelected: (val) => setState(() => _bidFilter = val),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Products')
                .where('bidders', arrayContains: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("คุณยังไม่เคยประมูลสินค้า", style: TextStyle(color: Colors.grey)));
              }

              // เตรียมตะกร้าแยกหมวดหมู่
              List<DocumentSnapshot> ongoingLeading = [];
              List<DocumentSnapshot> ongoingOutbid = [];
              List<DocumentSnapshot> endedWon = [];
              List<DocumentSnapshot> endedLost = [];

              // คัดแยกข้อมูล
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                bool isEnded = _isAuctionEnded(data);
                bool isLeading = data['highestBidderUid'] == user.uid;

                if (!isEnded) {
                  if (isLeading) ongoingLeading.add(doc);
                  else ongoingOutbid.add(doc);
                } else {
                  if (isLeading) endedWon.add(doc);
                  else endedLost.add(doc);
                }
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_bidFilter == 'All' || _bidFilter == 'Ongoing') ...[
                      if (ongoingLeading.isNotEmpty) _buildSection("👑 นำอยู่ (Leading)", Colors.green.shade600, ongoingLeading),
                      if (ongoingOutbid.isNotEmpty) _buildSection("⚠️ โดนแซง (Outbid)", Colors.orange.shade700, ongoingOutbid),
                    ],
                    if (_bidFilter == 'All' || _bidFilter == 'Ended') ...[
                      if (endedWon.isNotEmpty) _buildSection("🏆 ชนะการประมูล (Won)", const Color(0xFF6347EB), endedWon),
                      if (endedLost.isNotEmpty) _buildSection("❌ จบแล้ว/แพ้ (Lost)", Colors.grey.shade600, endedLost),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // แท็บ 2: สินค้าที่ฉันลงขาย (My Listings)
  // ==========================================
  Widget _buildListingsTab() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("กรุณาเข้าสู่ระบบ"));

    return Column(
      children: [
        _buildFilterChips(
          currentFilter: _listingFilter,
          onSelected: (val) => setState(() => _listingFilter = val),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Products')
                .where('sellerUid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("คุณยังไม่มีสินค้าที่ลงขาย", style: TextStyle(color: Colors.grey)));
              }

              List<DocumentSnapshot> ongoingListings = [];
              List<DocumentSnapshot> endedListings = [];

              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                if (_isAuctionEnded(data)) {
                  endedListings.add(doc);
             } else {
                  ongoingListings.add(doc);
                }
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_listingFilter == 'All' || _listingFilter == 'Ongoing') ...[
                      if (ongoingListings.isNotEmpty) _buildSection("🟢 กำลังเปิดประมูล (Ongoing)", Colors.green.shade600, ongoingListings),
                    ],
                    if (_listingFilter == 'All' || _listingFilter == 'Ended') ...[
                      if (endedListings.isNotEmpty) _buildSection("🔴 ปิดประมูลแล้ว (Ended)", Colors.redAccent, endedListings),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Widget ตัวช่วยต่างๆ
  // ==========================================
  
  // แถบปุ่มตัวกรอง (Choice Chips)
  Widget _buildFilterChips({required String currentFilter, required Function(String) onSelected}) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: ['All', 'Ongoing', 'Ended'].map((filter) {
          bool isSelected = currentFilter == filter;
          return ChoiceChip(
            label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
            selected: isSelected,
            selectedColor: const Color(0xFF6347EB),
            backgroundColor: Colors.grey.shade200,
            onSelected: (bool selected) {
              if (selected) onSelected(filter);
            },
          );
        }).toList(),
      ),
    );
  }

  // สร้าง Header และ GridView ของแต่ละหมวดหมู่
  Widget _buildSection(String title, Color color, List<DocumentSnapshot> docsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              Text("${docsList.length} items", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shrinkWrap: true,
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
        ),
      ],
    );
  }
}