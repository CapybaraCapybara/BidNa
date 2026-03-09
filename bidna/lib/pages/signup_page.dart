import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/social_button.dart';
import 'navigation_bar.dart';
import '../services/auth_service.dart'; // [เพิ่ม] Import AuthService ที่เราสร้างใหม่
import '../models/auth_result_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isSignIn = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  // [เพิ่ม] เรียกใช้งาน AuthService
  final AuthService _authService = AuthService();

  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 🔴 เรียกใช้ Service และรับผลลัพธ์กลับมาเป็น Model
    AuthResultModel result = await _authService.authenticateUser(
      isSignIn: _isSignIn,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _isSignIn ? null : _usernameController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // 🔴 เช็คจาก Model ว่าผ่านไหม
      if (result.isSuccess) {
        // สำเร็จ พาไปหน้า MainNavigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
      } else {
        // ไม่สำเร็จ เอาข้อความ Error จาก Model มาโชว์
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? "เกิดข้อผิดพลาด"), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo Section ---
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    size: 40,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                const SizedBox(height: 20),

                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Bid",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6C5CE7),
                          letterSpacing: -1,
                        ),
                      ),
                      TextSpan(
                        text: "Na",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D3436),
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Welcome back!",
                  style: TextStyle(color: Color(0xFFA4B0BE), fontSize: 16),
                ),
                const SizedBox(height: 30),

                // --- Main Card Section ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Toggle Switch
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildToggleBtn("Sign In", _isSignIn),
                              ),
                              Expanded(
                                child: _buildToggleBtn("Sign Up", !_isSignIn),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Inputs
                        CustomTextField(
                          label: "Email Address",
                          hint: "you@example.com",
                          prefixIcon: Icons.email_outlined,
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกอีเมล';
                            }
                            final emailRegex = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'รูปแบบอีเมลไม่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // แสดงช่อง Username เฉพาะตอน Sign Up
                        if (!_isSignIn) ...[
                          CustomTextField(
                            label: "Username",
                            hint: "ชื่อที่ต้องการแสดงในระบบ",
                            prefixIcon: Icons.person_outline,
                            controller: _usernameController,
                            validator: (value) {
                              if (!_isSignIn) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณากรอก Username';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username ต้องมีอย่างน้อย 3 ตัวอักษร';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        CustomTextField(
                          label: "Password",
                          hint: "••••••••",
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          isVisible: _isPasswordVisible,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกรหัสผ่าน';
                            }
                            if (value.length < 6) {
                              return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            }
                            return null;
                          },
                          onVisibilityToggle: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Sign In / Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isSignIn ? "Sign In" : "Sign Up",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "New to BidNa? ",
                      style: TextStyle(color: Color(0xFFA4B0BE)),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSignIn = false; 
                        });
                      },
                      child: const Text(
                        "Create an account",
                        style: TextStyle(
                          color: Color(0xFF6C5CE7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildToggleBtn(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSignIn = text == "Sign In";
          _formKey.currentState?.reset();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFF2D3436)
                  : const Color(0xFFA4B0BE),
            ),
          ),
        ),
      ),
    );
  }
}