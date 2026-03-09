import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bidna/pages/signup_page.dart'; // หรือ LoginScreen ตามที่คุณใช้งานจริง

// 🔴 Import Services
import 'package:bidna/services/user_service.dart';
import 'package:bidna/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _base64Image;
  bool _isLoading = true; 
  bool _isSaving = false; 

  // 🔴 เรียกใช้ Service (B4)
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // B4: เรียกผ่าน AuthService
    final uid = _authService.getCurrentUserId();
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // B4: เรียกผ่าน UserService (ดึงข้อมูล)
      final userDoc = await _userService.getUserData(uid);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['displayName'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _base64Image = data['profileImage']; 
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      // B4: เรียกผ่าน UserService (ประมวลผลรูป)
      String base64String = await _userService.processImageToBase64(file);
      setState(() {
        _base64Image = base64String;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      // B4: เรียกผ่าน UserService (บันทึกข้อมูล)
      await _userService.updateProfile(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        base64Image: _base64Image,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("อัปเดตโปรไฟล์สำเร็จ!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    // B4: เรียกผ่าน AuthService
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, 
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "ออกจากระบบ",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // B2: แยก Widget รูปโปรไฟล์
                    ProfileAvatarPicker(
                      base64Image: _base64Image,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _authService.getCurrentUser()?.email ?? "No Email",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    _buildTextField(
                      controller: _nameController,
                      label: "Username",
                      hint: "Enter your username",
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty ? "กรุณากรอกชื่อผู้ใช้" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      hint: "Enter your phone number",
                      icon: Icons.phone_outlined,
                      isPhone: true,
                      validator: (value) => value!.isEmpty ? "กรุณากรอกเบอร์โทรศัพท์" : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // About Me Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("About Me", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          maxLength: 150,
                          decoration: InputDecoration(
                            hintText: "Tell others a little about yourself...",
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.info_outline, color: Colors.grey),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FD),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            counterStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6347EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Save Profile",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPhone = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF8F9FD), 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// B2: แยก Widget การเลือกรูปโปรไฟล์ออกมาเพื่อความสะอาดของโค้ด
// ======================================================================
class ProfileAvatarPicker extends StatelessWidget {
  final String? base64Image;
  final VoidCallback onTap;

  const ProfileAvatarPicker({
    super.key,
    required this.base64Image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: base64Image != null && base64Image!.isNotEmpty
                ? MemoryImage(base64Decode(base64Image!))
                : null,
            child: base64Image == null || base64Image!.isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF6347EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}