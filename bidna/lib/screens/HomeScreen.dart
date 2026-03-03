import 'dart:convert';
import 'package:bidna/screens/profile_page.dart';
import 'package:bidna/widgets/filter_modal.dart';
import 'package:bidna/widgets/product_card.dart';
import 'package:bidna/screens/product_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bidna/screens/notification_screen.dart';
import 'package:bidna/widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State สำหรับ Filter
  RangeValues _currentPriceRange = const RangeValues(0, 100000); 
  String _selectedStatus = "All";
  String _searchQuery = "";
  String selectedCategory = "All";

  final List<String> categories = [
    "All",
    "Electronics",
    "Fashion",
    "Home",
    "Collectibles",
    "Others",
  ];

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilterModal(
          currentRange: _currentPriceRange,
          currentStatus: _selectedStatus,
          onApply: (newRange, newStatus) {
            setState(() {
              _currentPriceRange = newRange;
              _selectedStatus = newStatus;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // --- Search Bar ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Auctions...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color.fromRGBO(241, 244, 248, 1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _openFilter,
                icon: const Icon(Icons.filter_list, color: Colors.black54),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 10),

          // --- Category Selector ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() => selectedCategory = category);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFF6347EB) : Colors.white,
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Products')
                  .orderBy('startTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // --- LOGIC การกรองและการตรวจสอบสถานะสินค้า ---
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String docId = doc.id;
                  
                  // 1. ตรวจสอบการหมดเวลา (Auto-Close)
                  final DateTime endTime = (data['endTime'] as Timestamp).toDate();
                  String currentStatus = (data['status'] ?? 'open').toString().toLowerCase();

                  if (DateTime.now().isAfter(endTime) && currentStatus == 'open') {
                    // อัปเดต DB เมื่อหมดเวลาแต่สถานะยังเป็น open
                    FirebaseFirestore.instance
                        .collection('Products')
                        .doc(docId)
                        .update({'status': 'closed'});
                    currentStatus = 'closed'; // ปรับค่าใน memory เพื่อใช้กรองต่อทันที
                  }

                  // 2. กรอง Category
                  final itemCategory = data['category'] ?? "Others";
                  final categoryMatch = selectedCategory == "All" || itemCategory == selectedCategory;

                  // 3. กรองราคา
                  final price = (data['currentPrice'] ?? 0).toDouble();
                  final priceMatch = price >= _currentPriceRange.start && price <= _currentPriceRange.end;

                  // 4. กรองชื่อ (Search)
                  final title = (data['title'] ?? "").toString().toLowerCase();
                  final searchMatch = title.contains(_searchQuery.toLowerCase());

                  // 5. กรองสถานะ (Status) - ตรวจสอบค่า 'All', 'Open', 'Closed'
                  final selectedStatusLower = _selectedStatus.toLowerCase();
                  final statusMatch = _selectedStatus == "All" || currentStatus == selectedStatusLower;

                  return categoryMatch && priceMatch && searchMatch && statusMatch;
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Live Auctions",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text("${filteredDocs.length} items"),
                        ],
                      ),
                    ),

                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(child: Text("No products found"))
                          : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: filteredDocs.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return ProductCard(
                                  data: data,
                                  productId: doc.id,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsPage(productId: doc.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromRGBO(238, 237, 237, 1),
    );
  }
}