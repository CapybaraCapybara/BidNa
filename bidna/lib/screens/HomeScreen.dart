import 'package:bidna/widgets/filter_modal.dart';
import 'package:bidna/widgets/product_card.dart';
import 'package:bidna/screens/product_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State สำหรับ Filter
  RangeValues _currentPriceRange = const RangeValues(0, 100000); // ตั้ง Max เยอะๆ ไว้ก่อน
  String _selectedStatus = "All";
  String _searchQuery = "";
  String selectedCategory = "All";

  final List<String> categories = [
    "All",
    "Electronics",
    "Fashion",
    "Collections",
    "Others"
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
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Bidna", style: TextStyle(color: Colors.black87)),
            Row(
              children: const [
                Icon(Icons.chat_bubble_outline, color: Colors.black54),
                SizedBox(width: 20),
                Icon(Icons.notifications_none, color: Colors.black54),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue : Colors.white,
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
          
          // --- Main Content (StreamBuilder) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ดึงข้อมูลทั้งหมดมาก่อน แล้วค่อยมา Filter ในแอป (Client-side filtering)
              // เพราะการ Filter หลายเงื่อนไขพร้อมกันใน Firestore ต้องทำ Index ยุ่งยาก
              stream: FirebaseFirestore.instance
                  .collection('Products')
                  .orderBy('startTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ข้อมูลดิบจาก Firebase
                final docs = snapshot.data!.docs;

                // --- LOGIC การกรองข้อมูล (Filter) อยู่ตรงนี้ ---
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // 1. กรอง Category
                  // ต้องดูว่าใน Firebase field ชื่อ 'category' ตรงกับที่เราส่งไปไหม
                  final itemCategory = data['category'] ?? "Others";
                  final categoryMatch = selectedCategory == "All" || itemCategory == selectedCategory;

                  // 2. กรองราคา
                  final price = (data['currentPrice'] ?? 0).toDouble();
                  final priceMatch = price >= _currentPriceRange.start &&
                                     price <= _currentPriceRange.end;

                  // 3. กรองชื่อ (Search)
                  final title = (data['title'] ?? "").toString().toLowerCase();
                  final searchMatch = title.contains(_searchQuery.toLowerCase());

                  // 4. กรองสถานะ (Status)
                  final status = data['status'] ?? "Open";
                  final statusMatch = _selectedStatus == "All" || status == _selectedStatus;

                  return categoryMatch && priceMatch && searchMatch && statusMatch;
                }).toList();

                // --- ส่วนหัว Live Auctions และจำนวนสินค้า ---
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Live Auctions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text("${filteredDocs.length} items"),
                        ],
                      ),
                    ),
                    
                    // --- GridView แสดงสินค้า ---
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
                          final String docId = doc.id; // ดึง ID document

                          return ProductCard(
                            data: data,        // ส่ง Map เข้าไปเลย
                            productId: docId,  // ส่ง ID แยก
                            onTap: () {
                              // ไปหน้า Detail
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ProductDetailsPage(productId: docId)
                              ));
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