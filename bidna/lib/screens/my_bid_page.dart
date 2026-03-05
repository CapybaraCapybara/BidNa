import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/widgets/product_card.dart';
import 'package:bidna/screens/product_details_page.dart';
import 'package:bidna/widgets/custom_app_bar.dart';
// 🔴 Import Model
import 'package:bidna/models/product_model.dart';

class MyBidPage extends StatefulWidget {
  const MyBidPage({super.key});

  @override
  State<MyBidPage> createState() => _MyBidPageState();
}

class _MyBidPageState extends State<MyBidPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _bidFilter = 'All'; 
  String _listingFilter = 'All'; 

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

  // 🔴 เปลี่ยนมาเช็คจาก ProductModel โดยตรง
  bool _isAuctionEnded(ProductModel product) {
    if (product.status.toLowerCase() == 'closed' || product.status.toLowerCase() == 'close') return true;
    if (product.endTime.isBefore(DateTime.now())) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(238, 237, 237, 1),
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
          _buildBidsTab(),
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

              // 🔴 แปลงเป็น List<ProductModel>
              List<ProductModel> ongoingLeading = [];
              List<ProductModel> ongoingOutbid = [];
              List<ProductModel> endedWon = [];
              List<ProductModel> endedLost = [];

              for (var doc in snapshot.data!.docs) {
                ProductModel product = ProductModel.fromDoc(doc);
                bool isEnded = _isAuctionEnded(product);
                bool isLeading = product.highestBidderUid == user.uid;

                if (!isEnded) {
                  if (isLeading) ongoingLeading.add(product);
                  else ongoingOutbid.add(product);
                } else {
                  if (isLeading) endedWon.add(product);
                  else endedLost.add(product);
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

              List<ProductModel> ongoingListings = [];
              List<ProductModel> endedListings = [];

              for (var doc in snapshot.data!.docs) {
                ProductModel product = ProductModel.fromDoc(doc);
                if (_isAuctionEnded(product)) {
                  endedListings.add(product);
                } else {
                  ongoingListings.add(product);
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

  // 🔴 เปลี่ยนจากการรับ DocumentSnapshot มาเป็น ProductModel
  Widget _buildSection(String title, Color color, List<ProductModel> productList) {
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
              Text("${productList.length} items", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final product = productList[index];
            return ProductCard(
              product: product, // 🔴 ใช้ ProductModel
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailsPage(productId: product.id)),
                );
              },
            );
          },
        ),
      ],
    );
  }
}