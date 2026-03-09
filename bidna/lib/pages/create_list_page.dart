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
import 'package:bidna/services/auth_service.dart';
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
  final AuthService _authService = AuthService();

  List<File> _selectedImages = [];
  String? _selectedCategory;
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  
  // 1. เพิ่มตัวแปรนี้เพื่อเช็คว่าเคยกดปุ่มสร้างหรือยัง
  bool _isSubmitted = false; 

  String? _imageError;
  String? _dateTimeError;

  final List<String> _categories = ['Electronics', 'Fashion', 'Home', 'Collectibles', 'Others'];
  final ProductService _productService = ProductService();

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) return;
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
        _imageError = null; 
      });
    }
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
          _dateTimeError = null; 
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
    // 2. จับมัดรวมทุกอย่างไว้ใน setState เดียว
    setState(() {
      _isSubmitted = true; // บังคับให้ Form พ่นสีแดงออกมาทุกช่องทันที
      
      _imageError = _selectedImages.isEmpty ? "Please add at least 1 photo" : null;
      
      if (_selectedDateTime == null) {
        _dateTimeError = "Please select auction end date & time";
      } else if (_selectedDateTime!.isBefore(DateTime.now())) {
        _dateTimeError = "End time must be in the future";
      } else {
        _dateTimeError = null;
      }
    });

    // ให้ Form ตรวจสอบว่าช่อง TextField ผิดไหม
    bool isFormValid = _formKey.currentState!.validate();

    // หากมี Error ให้หยุดการทำงานทันที
    if (!isFormValid || _imageError != null || _dateTimeError != null) {
      return; 
    }

    setState(() => _isLoading = true);
    try {
      List<String> base64Images = [];
      for (var file in _selectedImages) {
        base64Images.add(await _processImageToBase64(file));
      }

      User? currentUser = _authService.getCurrentUser();
      
      await _productService.createListing({
        'category': _selectedCategory,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
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
    setState(() { 
      _selectedImages = []; 
      _selectedCategory = null; 
      _selectedDateTime = null; 
      _imageError = null;
      _dateTimeError = null;
      _isSubmitted = false; // ล้างค่าเผื่อสร้างสินค้าชิ้นต่อไป
    });
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
              // 3. ตรงนี้คือหัวใจสำคัญ: ถ้ากดยืนยันแล้ว ให้บังคับโชว์ Error เสมอ
              autovalidateMode: _isSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Photos *", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildPhotoArea(),
                  
                  if (_imageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(_imageError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                    ),
                  
                  _buildInputLabel("Title *"),
                  _buildTextField(
                    _titleController, 
                    "Item name",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter item name" : null,
                  ),
                  
                  _buildInputLabel("Description (Optional)"),
                  _buildTextField(
                    _descController, 
                    "Details...", 
                    maxLines: 3,
                  ),
                  
                  _buildInputLabel("Category *"),
                  _buildCategoryDropdown(), 
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("Starting Price (฿) *"),
                            _buildTextField(
                              _priceController, 
                              "0.00", 
                              isNumber: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return "Required";
                                final val = double.tryParse(v);
                                if (val == null) return "Invalid number";
                                if (val < 0) return "Cannot be negative";
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("Min Bid (฿) *"),
                            _buildTextField(
                              _minBidController, 
                              "e.g. 50", 
                              isNumber: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return "Required";
                                final val = double.tryParse(v);
                                if (val == null) return "Invalid number";
                                if (val <= 0) return "Must be > 0";
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  _buildInputLabel("Auction End Date & Time *"),
                  GestureDetector(
                    onTap: _selectDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50, 
                        borderRadius: BorderRadius.circular(10), 
                        border: Border.all(color: _dateTimeError != null ? Colors.red.shade700 : Colors.grey.shade200)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateTime == null ? "Select End Date & Time" : DateFormat('dd MMM yyyy, HH:mm').format(_selectedDateTime!),
                            style: TextStyle(
                              color: _selectedDateTime == null ? Colors.grey : Colors.black, 
                              fontWeight: _selectedDateTime == null ? FontWeight.normal : FontWeight.bold
                            )
                          ),
                          const Icon(Icons.calendar_today, color: Color(0xFF6347EB), size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_dateTimeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(_dateTimeError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
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
    return Wrap(
      spacing: 10,
      runSpacing: 10, // เพิ่มระยะห่างระหว่างบรรทัดเว้นรูปหล่นลงมา
      children: [
        ..._selectedImages.asMap().entries.map((entry) {
          int index = entry.key;
          File file = entry.value;
          return Stack(
            children: [
              // ตัวรูปภาพ
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              // ปุ่มลบรูป (กากบาทสีแดง) มุมขวาบน
              Positioned(
                top: -5,
                right: -5,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    // ลบรูปออกจาก List และอัปเดตหน้าจอ
                    setState(() {
                      _selectedImages.removeAt(index);
                      // ถ้าลบจนหมด และเคยกดปุ่มสร้างไปแล้ว ให้พ่น Error กลับมา
                      if (_selectedImages.isEmpty && _isSubmitted) {
                        _imageError = "Please add at least 1 photo";
                      }
                    });
                  },
                ),
              ),
            ],
          );
        }).toList(),
        
        // ปุ่มเพิ่มรูปภาพ
        if (_selectedImages.length < 5)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(
                    color: _imageError != null
                        ? Colors.red.shade700
                        : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Icon(
                Icons.add_a_photo,
                color: _imageError != null ? Colors.red.shade700 : Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputLabel(String t) => Padding(padding: const EdgeInsets.only(top: 15, bottom: 5), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)));
  
  Widget _buildTextField(TextEditingController c, String h, {int maxLines = 1, bool isNumber = false, String? Function(String?)? validator}) => TextFormField(
    controller: c, 
    maxLines: maxLines, 
    keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    decoration: InputDecoration(
      hintText: h, 
      filled: true, 
      fillColor: Colors.grey.shade50, 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      errorStyle: TextStyle(color: Colors.red.shade700)
    ),
    validator: validator,
  );

  Widget _buildCategoryDropdown() => DropdownButtonFormField<String>(
    value: _selectedCategory,
    decoration: InputDecoration(
      hintText: "Select Category",
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      errorStyle: TextStyle(color: Colors.red.shade700)
    ),
    items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: (v) => setState(() => _selectedCategory = v),
    validator: (v) => v == null ? "Please select a category" : null,
  );
}