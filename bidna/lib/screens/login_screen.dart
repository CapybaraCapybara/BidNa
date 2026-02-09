import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // [เพิ่ม] นำเข้า Firebase Auth
import '../widgets/custom_textfield.dart';
import '../widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isSignIn = true;

  // [เพิ่ม] ตัวแปรสำหรับเชื่อมกับระบบหลังบ้าน
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // ตัวแปรสำหรับทำสถานะหมุนโหลด

  // [เพิ่ม] ฟังก์ชันสำหรับ สมัครสมาชิก และ ล็อกอิน
  Future<void> _submitAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential;
      if (_isSignIn) {
        // กรณีล็อกอิน
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // กรณีสมัครสมาชิกใหม่
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
      }

      // เมื่อสำเร็จ ให้ส่งข้อมูล user ไปหน้าถัดไป (หน้า Home)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: userCredential.user!),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // แจ้งเตือนถ้ากรอกรหัสผิด หรือเมลซ้ำ
      String message = e.message ?? "เกิดข้อผิดพลาด";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // [เพิ่ม] คืนหน่วยความจำเมื่อปิดหน้า
    _emailController.dispose();
    _passwordController.dispose();
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
                // --- Logo Section --- (UI เดิม 100%)
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text(
                      "Na",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3436),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
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
                  child: Column(
                    children: [
                      // Toggle Switch (Sign In / Sign Up)
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

                      // Social Buttons
                      Row(
                        children: [
                          SocialButton(
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 30,
                              color: Colors.black,
                            ),
                            onTap: () {},
                          ),
                          const SizedBox(width: 16),
                          SocialButton(
                            icon: const Icon(
                              Icons.apple,
                              size: 30,
                              color: Colors.black,
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFDFE6E9))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "OR CONTINUE WITH EMAIL",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFA4B0BE),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFDFE6E9))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Inputs
                      CustomTextField(
                        label: "Email Address",
                        hint: "you@example.com",
                        prefixIcon: Icons.email_outlined,
                        controller:
                            _emailController, // [เพิ่ม] เรียกใช้ controller
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: "Password",
                        hint: "••••••••",
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        controller:
                            _passwordController, // [เพิ่ม] เรียกใช้ controller
                        onVisibilityToggle: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign In / Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          // [เพิ่ม] กดปุ่มแล้วไปเรียกฟังก์ชัน _submitAuth
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
                                      // [แก้] เปลี่ยนข้อความบนปุ่มตามสถานะว่ากำลัง Sign In หรือ Sign Up
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
                      onTap: () {},
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

// ==========================================================
// [เพิ่ม] หน้าจอรับค่าหลังจาก Login สำเร็จ (แยกไฟล์ได้ แต่ใส่ไว้ล่างสุดเพื่อให้ลองรันได้เลย)
// ==========================================================
class HomeScreen extends StatelessWidget {
  final User user; // ตัวแปรรับค่า User

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BidNa Home"),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "เข้าสู่ระบบสำเร็จ!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "อีเมลของคุณคือ: ${user.email}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // คำสั่งออกจากระบบ
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                "ออกจากระบบ",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
