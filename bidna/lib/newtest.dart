import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MainNavigation(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Kanit', // หากคุณมีฟอนต์ภาษาไทย
    ),
  ));
}

// --- 1. ระบบ Navigation หลัก ---
class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ProductListPage(),
    CreateListingBase64(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF6347EB),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
        ],
      ),
    );
  }
}

// --- 2. หน้าแสดงรายการสินค้าทั้งหมด (Explore) ---
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BidNa Marketplace", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Products').orderBy('startTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              List images = data['images'] ?? [];
              
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProductDetailsPage(productId: docs[index].id)
                )),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: images.isNotEmpty
                            ? Image.memory(base64Decode(images[0]), fit: BoxFit.cover, width: double.infinity)
                            : Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['title'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("฿${NumberFormat('#,###').format(data['currentPrice'])}", 
                                style: const TextStyle(color: Color(0xFF6347EB), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 3. หน้าสร้างรายการประมูล (Create) + ปรับปรุง Date & Time Picker ---
class CreateListingBase64 extends StatefulWidget {
  @override
  _CreateListingBase64State createState() => _CreateListingBase64State();
}

class _CreateListingBase64State extends State<CreateListingBase64> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<File> _selectedImages = [];
  String? _selectedCategory;
  DateTime? _selectedDateTime; // เก็บทั้งวันและเวลาที่เลือก
  bool _isLoading = false;

  final List<String> _categories = ['Electronics', 'Fashion', 'Home', 'Collectibles'];

  // ฟังก์ชันเลือกรูป
  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) return;
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedImages.add(File(pickedFile.path)));
  }

  // ฟังก์ชันเลือกวันและเวลาที่ละเอียด
  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<String> _processImageToBase64(File file) async {
    Uint8List bytes = await file.readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return "";
    img.Image resized = img.copyResize(decoded, width: 500);
    List<int> compressed = img.encodeJpg(resized, quality: 60);
    return base64Encode(compressed);
  }

  Future<void> _startAuction() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty || _selectedCategory == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลและเลือกเวลาจบให้ครบถ้วน")));
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("เวลาจบต้องอยู่หลังจากเวลาปัจจุบัน")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<String> base64Images = [];
      for (var file in _selectedImages) {
        base64Images.add(await _processImageToBase64(file));
      }

      await FirebaseFirestore.instance.collection('Products').add({
        'category': _selectedCategory,
        'title': _titleController.text,
        'description': _descController.text,
        'images': base64Images,
        'startPrice': double.parse(_priceController.text),
        'currentPrice': double.parse(_priceController.text),
        'startTime': FieldValue.serverTimestamp(),
        'endTime': Timestamp.fromDate(_selectedDateTime!),
        'status': 'open',
        'sellerId': 'user_123_test',
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("สร้างรายการสำเร็จ!")));
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    _priceController.clear();
    setState(() { _selectedImages = []; _selectedCategory = null; _selectedDateTime = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Listing", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Photos", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildPhotoArea(),
                  _buildInputLabel("Title"),
                  _buildTextField(_titleController, "Item name"),
                  _buildInputLabel("Description"),
                  _buildTextField(_descController, "Details...", maxLines: 3),
                  _buildInputLabel("Category"),
                  _buildDropdown(_categories, "Select Category", (v) => setState(() => _selectedCategory = v), _selectedCategory),
                  _buildInputLabel("Starting Price (฿)"),
                  _buildTextField(_priceController, "0.00", isNumber: true),
                  
                  _buildInputLabel("Auction End Date & Time"),
                  GestureDetector(
                    onTap: _selectDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedDateTime == null ? "Select End Date & Time" : DateFormat('dd MMM yyyy, HH:mm').format(_selectedDateTime!),
                               style: TextStyle(color: _selectedDateTime == null ? Colors.grey : Colors.black, fontWeight: _selectedDateTime == null ? FontWeight.normal : FontWeight.bold)),
                          const Icon(Icons.calendar_today, color: Color(0xFF6347EB), size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startAuction,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6347EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text("Start Auction", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    return Wrap(spacing: 10, children: [
      ..._selectedImages.map((file) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover))),
      if (_selectedImages.length < 5)
        GestureDetector(
          onTap: _pickImage,
          child: Container(width: 70, height: 70, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade50), child: const Icon(Icons.add_a_photo, color: Colors.grey)),
        ),
    ]);
  }

  Widget _buildInputLabel(String t) => Padding(padding: const EdgeInsets.only(top: 15, bottom: 5), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)));
  
  Widget _buildTextField(TextEditingController c, String h, {int maxLines = 1, bool isNumber = false}) => TextFormField(
    controller: c, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(hintText: h, filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
    validator: (v) => v!.isEmpty ? "Required" : null,
  );

  Widget _buildDropdown(List<String> items, String hint, ValueChanged<String?> onChanged, String? val) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: val, isExpanded: true, hint: Text(hint), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged)),
  );
}

// --- 4. หน้าแสดงรายละเอียดสินค้า (Details) ---
class ProductDetailsPage extends StatelessWidget {
  final String productId;
  ProductDetailsPage({required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Products').doc(productId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          List images = data['images'] ?? [];
          DateTime endTime = (data['endTime'] as Timestamp).toDate();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  SizedBox(
                    height: 400,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (_, i) => Image.memory(base64Decode(images[i]), fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['category'] ?? "", style: const TextStyle(color: Color(0xFF6347EB), fontWeight: FontWeight.bold)),
                      Text(data['title'] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _info("Current Bid", "฿${NumberFormat('#,###').format(data['currentPrice'])}"),
                          _info("Ends at", DateFormat('dd MMM, HH:mm').format(endTime)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? "", style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement Bidding System
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6347EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("Place a Bid", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _info(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ]);
}