import 'package:bidna/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:bidna/models/product_model.dart';
import 'package:bidna/widgets/filter_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RangeValues _currentPriceRange = const RangeValues(0, 2000);
  String _selectedStatus = "All";
  String _searchQuery = "";

  List<Product> getFilteredProducts() {
    return allProducts.where((p) {
      // 1. กรอง Category
      final categoryMatch =
          selectedCategory == "All" || p.category == selectedCategory;

      // 2. กรองราคา (ให้อยู่ในช่วง min-max ที่เลือก)
      final priceMatch =
          p.price >= _currentPriceRange.start &&
          p.price <= _currentPriceRange.end;

      final searchMatch = p.productTitle.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      // 3. กรองสถานะ
      final statusMatch =
          _selectedStatus == "All" || p.status == _selectedStatus;

      return categoryMatch && priceMatch && statusMatch && searchMatch;
    }).toList();
  }

  String selectedCategory = "All";

  final List<String> categories = [
    "All",
    "Electronics",
    "Fashion",
    "Collections",
  ];

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // เรียกใช้ Widget ที่เราแยกไว้
        return FilterModal(
          currentRange: _currentPriceRange, // ส่งค่าปัจจุบันเข้าไป
          currentStatus: _selectedStatus,
          onApply: (newRange, newStatus) {
            // รับค่ากลับมา แล้วสั่ง setState หน้าหลัก
            setState(() {
              _currentPriceRange = newRange;
              _selectedStatus = newStatus;
            });
          },
        );
      },
    );
  }

  final List<Product> allProducts = [
    Product(
      productTitle: "iPhone 15",
      bids: 5,
      category: "Electronics",
      price: 999,
      imageUrl:
          "https://cdn.siamphone.com/spec/apple/images/iphone_15/1694676311_09-apple-iphone-15.jpg",
      status: "Open",
    ),
    Product(
      productTitle: "Laptop",
      bids: 10,
      category: "Electronics",
      price: 1200,
      imageUrl:
          "https://www.jib.co.th/img_master/product/original/2025062715451478016_1.jpg",
      status: "Closed",
    ),
    Product(
      productTitle: "T-Shirt",
      bids: 20,
      category: "Fashion",
      price: 20,
      imageUrl:
          "https://i.pinimg.com/236x/af/b5/a2/afb5a2a116463f0df214f907dd25a507.jpg",
      status: "Open",
    ),
    Product(
      productTitle: "Jeans",
      bids: 124,
      category: "Fashion",
      price: 50,
      imageUrl:
          "https://shop.mango.com/assets/rcs/pics/static/T7/fotos/S/77014030_TM_B.jpg?imwidth=2048&imdensity=1&ts=1720460135089",
      status: "Open",
    ),
    Product(
      productTitle: "Pokemon Card",
      bids: 5,
      category: "Collections",
      price: 500,
      imageUrl:
          "https://www.toronto-collective.com/cdn/shop/files/P9488_290-85568_03_1200x.jpg?v=1700692297",
      status: "Closed",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Bidna", style: TextStyle(color: Colors.black87)),
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Auctions...',
                      prefixIcon: Icon(Icons.search, color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color.fromRGBO(241, 244, 248, 1),
                      focusColor: Color.fromRGBO(96, 103, 237, 1),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  onPressed: _openFilter,
                  icon: Icon(Icons.filter_list, color: Colors.black54),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    hoverColor: const Color.fromARGB(255, 109, 109, 109),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 10),
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
                        backgroundColor: isSelected
                            ? Colors.blue
                            : Colors.white,
                        foregroundColor: isSelected
                            ? Colors.white
                            : Colors.black,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Row(
                    children: [
                      SizedBox(width: 20),
                      Text(
                        "Live Auctions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  child: Row(children: [Text("6 items"), SizedBox(width: 20)]),
                ),
              ],
            ),

            Expanded(
              // แนะนำ GridView.builder แทน ListView ถ้าอยากได้แถวละ 2 รูป
              child: GridView.builder(
                padding: EdgeInsets.all(10),
                itemCount: filteredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 รูปต่อแถว
                  childAspectRatio: 0.75, // อัตราส่วน กว้าง/สูง ของการ์ด
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];

                  // เรียกใช้ Widget ProductCard ของคุณ
                  return ProductCard(product: product);
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color.fromRGBO(238, 237, 237, 1),
    );
  }
}
