import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bidna/services/withdraw_service.dart'; 

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController _amountController = TextEditingController();
  final WithdrawService _withdrawService = WithdrawService(); // เรียกใช้งาน Service
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ตรวจสอบข้อมูลและดึง Pop-up ยืนยัน
  Future<void> _validateAndConfirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String input = _amountController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('กรุณากรอกจำนวน Coupon ที่ต้องการถอน', Colors.red);
      return;
    }

    final int? withdrawAmount = int.tryParse(input);
    if (withdrawAmount == null || withdrawAmount <= 0) {
      _showSnackBar('กรุณากรอกจำนวนตัวเลขให้ถูกต้อง (มากกว่า 0)', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 👇 เรียกใช้ Service เพื่อดึงยอดเงินปัจจุบัน
      final currentBalance = await _withdrawService.getCurrentBalance(user.uid);

      setState(() => _isLoading = false);

      if (currentBalance < withdrawAmount) {
        _showSnackBar('ยอด Coupon ของคุณไม่เพียงพอ (มีอยู่ ${NumberFormat('#,###').format(currentBalance)})', Colors.red);
        return;
      }

      // ถ้าเงินพอ ให้แสดงกล่องยืนยัน
      _showConfirmationDialog(withdrawAmount, user.uid);

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('เกิดข้อผิดพลาดในการตรวจสอบยอดเงิน', Colors.red);
    }
  }

  // แสดงกล่องยืนยัน
  void _showConfirmationDialog(int amount, String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6347EB)),
              SizedBox(width: 8),
              Text('ยืนยันการถอนเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'คุณต้องการถอนเงินจำนวน ${NumberFormat('#,###').format(amount)} Coupons ใช่หรือไม่?\n\n'
            '*ระบบจะทำการโอนเงินเข้าบัญชีธนาคารที่คุณผูกไว้ในหน้าโปรไฟล์',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // ปิด Pop-up
                _processWithdraw(amount, uid); // ไปดำเนินการถอนเงิน
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6347EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ทำการหักเงินผ่าน Service
  Future<void> _processWithdraw(int amount, String uid) async {
    setState(() => _isLoading = true);

    try {
      // 👇 โยนหน้าที่หักเงินให้ Service จัดการ
      await _withdrawService.processWithdraw(uid, amount);

      if (mounted) {
        _showSnackBar('ทำรายการถอนเงินสำเร็จ! 💸', Colors.green);
        Navigator.pop(context); // กลับหน้าหลัก
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการถอนเงิน: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Withdraw", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: user == null
          ? const Center(child: Text("กรุณาล็อกอินก่อนใช้งาน"))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6347EB), Color(0xFF8B75FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6347EB).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ยอด Coupon คงเหลือ", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        // 👇 เรียกใช้ Stream จาก Service
                        StreamBuilder<DocumentSnapshot>(
                          stream: _withdrawService.getUserBalanceStream(user.uid),
                          builder: (context, snapshot) {
                            int balance = 0;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              balance = (snapshot.data!.data() as Map<String, dynamic>)['couponBalance']?.toInt() ?? 0;
                            }
                            return Row(
                              children: [
                                const Icon(Icons.local_activity, color: Colors.amber, size: 32),
                                const SizedBox(width: 8),
                                Text(
                                  NumberFormat('#,###').format(balance),
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text("ระบุจำนวนที่ต้องการถอน", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    "ระบบจะทำการโอนเงินเข้าบัญชีธนาคารที่คุณผูกไว้",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6347EB)),
                    decoration: InputDecoration(
                      hintText: "0",
                      prefixIcon: const Icon(Icons.money_off, color: Color(0xFF6347EB)),
                      suffixText: "Coupons",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF6347EB), width: 2),
                      ),
                    ),
                  ),
                  
                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndConfirm, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6347EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "ดำเนินการถอนเงิน",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}