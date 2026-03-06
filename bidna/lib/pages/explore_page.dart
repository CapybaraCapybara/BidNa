import 'dart:convert';
import 'package:bidna/pages/profile_page.dart';
import 'package:bidna/widgets/filter_modal.dart';
import 'package:bidna/widgets/product_card.dart';
import 'package:bidna/pages/product_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bidna/pages/notification_page.dart';
import 'package:bidna/widgets/custom_app_bar.dart';

// 🔴 Import Model & Service
import 'package:bidna/models/product_model.dart';
import 'package:bidna/services/product_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RangeValues _currentPriceRange = const RangeValues(0, 100000); 
  String _selectedStatus = "All";
  String _searchQuery = "";
  String selectedCategory = "All";

  // 🔴 เรียกใช้งาน Service
  final ProductService _productService = ProductService();

  final List<String> categories = [
    "All", "Electronics", "Fashion", "Home", "Collectibles", "Others",
  ];

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search Auctions...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TextButton(
                    onPressed: () => setState(() => selectedCategory = category),
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
              stream: _productService.getLiveAuctions(), // 🔴 ดึง Stream จาก Service
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 🔴 แปลง Document ให้เป็น ProductModel List
                final products = snapshot.data!.docs.map((doc) => ProductModel.fromDoc(doc)).toList();

                final filteredProducts = products.where((product) {
                  String currentStatus = product.status.toLowerCase();

                  // ตรวจสอบ Auto-Close
                  if (DateTime.now().isAfter(product.endTime) && currentStatus == 'open') {
                    _productService.closeAuction(product.id); // 🔴 สั่งปิดผ่าน Service
                    currentStatus = 'closed';
                  }

                  final categoryMatch = selectedCategory == "All" || product.category == selectedCategory;
                  final priceMatch = product.currentPrice >= _currentPriceRange.start && product.currentPrice <= _currentPriceRange.end;
                  final searchMatch = product.title.toLowerCase().contains(_searchQuery.toLowerCase());
                  final statusMatch = _selectedStatus == "All" || currentStatus == _selectedStatus.toLowerCase();

                  return categoryMatch && priceMatch && searchMatch && statusMatch;
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Live Auctions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("${filteredProducts.length} items"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(child: Text("No products found"))
                          : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: filteredProducts.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ProductCard(
                                  product: product, // 🔴 โยน ProductModel เข้า ProductCard
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsPage(productId: product.id),
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