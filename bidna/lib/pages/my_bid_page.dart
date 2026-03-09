import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Widgets & Pages
import 'package:bidna/widgets/product_card.dart';
import 'package:bidna/pages/product_details_page.dart';
import 'package:bidna/widgets/custom_app_bar.dart';

// Models & Services (B4)
import 'package:bidna/models/product_model.dart';
import 'package:bidna/services/product_service.dart';

class MyBidPage extends StatefulWidget {
  const MyBidPage({super.key});

  @override
  State<MyBidPage> createState() => _MyBidPageState();
}

class _MyBidPageState extends State<MyBidPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductService _productService = ProductService(); // B4: เรียกใช้ Service
  final User? _currentUser = FirebaseAuth.instance.currentUser;

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

  // B3: แยก Logic การจัดกลุ่มข้อมูลออกจาก build method เพื่อไม่ให้ build ทำงานหนัก
  Map<String, List<ProductModel>> _categorizeBids(List<ProductModel> products) {
    final Map<String, List<ProductModel>> categorized = {
      'ongoingLeading': [], 'ongoingOutbid': [], 'endedWon': [], 'endedLost': []
    };

    if (_currentUser == null) return categorized;

    for (var product in products) {
      bool isEnded = _productService.isAuctionEnded(product);
      bool isLeading = product.highestBidderUid == _currentUser.uid;

      if (!isEnded) {
        if (isLeading) categorized['ongoingLeading']!.add(product);
        else categorized['ongoingOutbid']!.add(product);
      } else {
        if (isLeading) categorized['endedWon']!.add(product);
        else categorized['endedLost']!.add(product);
      }
    }
    return categorized;
  }

  Map<String, List<ProductModel>> _categorizeListings(List<ProductModel> products) {
    final Map<String, List<ProductModel>> categorized = {'ongoing': [], 'ended': []};
    for (var product in products) {
      if (_productService.isAuctionEnded(product)) {
        categorized['ended']!.add(product);
      } else {
        categorized['ongoing']!.add(product);
      }
    }
    return categorized;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(238, 237, 237, 1),
      appBar: CustomAppBar(
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6347EB),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6347EB),
          indicatorWeight: 3,
          tabs: const [Tab(text: "My Bids"), Tab(text: "My Listings")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBidsTab(), _buildListingsTab()],
      ),
    );
  }

  Widget _buildBidsTab() {
    return Column(
      children: [
        FilterChipGroup( // B2: ใช้ Widget ที่แยกออกไป
          currentFilter: _bidFilter,
          onSelected: (val) => setState(() => _bidFilter = val),
        ),
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productService.getMyBidsStream(_currentUser!.uid),
            builder: (context, snapshot) {
              // B5: Error Handling
              if (snapshot.hasError) return const Center(child: Text('Something went wrong.'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("You haven't bid on any products yet.", style: TextStyle(color: Colors.grey)));
              }

              final categorized = _categorizeBids(snapshot.data!);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_bidFilter == 'All' || _bidFilter == 'Ongoing') ...[
                      if (categorized['ongoingLeading']!.isNotEmpty)
                        ProductGridSection(title: "👑 Leading", color: Colors.green.shade600, products: categorized['ongoingLeading']!),
                      if (categorized['ongoingOutbid']!.isNotEmpty)
                        ProductGridSection(title: "⚠️ Outbid", color: Colors.orange.shade700, products: categorized['ongoingOutbid']!),
                    ],
                    if (_bidFilter == 'All' || _bidFilter == 'Ended') ...[
                      if (categorized['endedWon']!.isNotEmpty)
                        ProductGridSection(title: "🏆 Won", color: const Color(0xFF6347EB), products: categorized['endedWon']!),
                      if (categorized['endedLost']!.isNotEmpty)
                        ProductGridSection(title: "❌ Lost", color: Colors.grey.shade600, products: categorized['endedLost']!),
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

  Widget _buildListingsTab() {
    return Column(
      children: [
        FilterChipGroup(
          currentFilter: _listingFilter,
          onSelected: (val) => setState(() => _listingFilter = val),
        ),
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productService.getMyListingsStream(_currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Something went wrong.'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("You don't have any listings yet.", style: TextStyle(color: Colors.grey)));
              }

              final categorized = _categorizeListings(snapshot.data!);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_listingFilter == 'All' || _listingFilter == 'Ongoing') ...[
                      if (categorized['ongoing']!.isNotEmpty)
                        ProductGridSection(title: "🟢 Ongoing", color: Colors.green.shade600, products: categorized['ongoing']!),
                    ],
                    if (_listingFilter == 'All' || _listingFilter == 'Ended') ...[
                      if (categorized['ended']!.isNotEmpty)
                        ProductGridSection(title: "🔴 Ended", color: Colors.redAccent, products: categorized['ended']!),
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
}

// ======================================================================
// B2: แยก Widgets ออกมาเป็นคลาสเพื่อให้โค้ด Clean (สามารถย้ายไปโฟลเดอร์ widgets/ ได้)
// ======================================================================

class FilterChipGroup extends StatelessWidget {
  final String currentFilter;
  final Function(String) onSelected;

  const FilterChipGroup({super.key, required this.currentFilter, required this.onSelected});

  @override
  Widget build(BuildContext context) {
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
}

class ProductGridSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<ProductModel> products;

  const ProductGridSection({super.key, required this.title, required this.color, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              Text("${products.length} items", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
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