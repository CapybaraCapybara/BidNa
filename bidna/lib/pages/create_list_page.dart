import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:bidna/widgets/custom_app_bar.dart';
// 🔴 Import Service
import 'package:bidna/services/product_service.dart';

class CreateListingBase64 extends StatefulWidget {
  @override
  _CreateListingBase64State createState() => _CreateListingBase64State();
}

class _CreateListingBase64State extends State<CreateListingBase64> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _minBidController = TextEditingController();

  List<File> _selectedImages = [];
  String? _selectedCategory;
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  final List<String> _categories = ['Electronics', 'Fashion', 'Home', 'Collectibles', 'Others'];
  
  // 🔴 เรียกใช้ Service
  final ProductService _productService = ProductService();

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) return;
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedImages.add(File(pickedFile.path)));
  }

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

      User? currentUser = FirebaseAuth.instance.currentUser;
      
      // 🔴 ส่งข้อมูลให้ ProductService จัดการสร้างรายการ
      await _productService.createListing({
        'category': _selectedCategory,
        'title': _titleController.text,
        'description': _descController.text,
        'images': base64Images,
        'startPrice': double.parse(_priceController.text),
        'currentPrice': double.parse(_priceController.text),
        'minBidIncrement': double.parse(_minBidController.text),
        'startTime': FieldValue.serverTimestamp(),
        'endTime': Timestamp.fromDate(_selectedDateTime!),
        'status': 'open',
        'sellerUid': currentUser?.uid,  
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Created listing successfully!")));
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
    _minBidController.clear();
    setState(() { _selectedImages = []; _selectedCategory = null; _selectedDateTime = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("Starting Price (฿)"),
                            _buildTextField(_priceController, "0.00", isNumber: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("Min Bid (฿)"),
                            _buildTextField(_minBidController, "e.g. 50", isNumber: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
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
                      child: const Text("Start Auction", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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