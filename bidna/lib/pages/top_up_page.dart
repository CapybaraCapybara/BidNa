import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bidna/services/top_up_service.dart';
import 'package:bidna/pages/withdraw_page.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  // ลิสต์จำนวนเงินที่เราจะให้ผู้ใช้เติมได้
  final List<int> _topUpAmounts = [100, 500, 1000, 3000, 5000, 10000];
  final TopUpService _topUpService = TopUpService(); // 👇 เรียกใช้งาน Service
  bool _isLoading = false;

  // ฟังก์ชันจำลองการเติมเงินผ่าน Service
  Future<void> _processTopUp(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 👇 โยนหน้าที่การบวกเงินให้ Service จัดการ
      await _topUpService.processTopUp(user.uid, amount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Top up successful! +${NumberFormat('#,###').format(amount)} Coupons 🎉',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // เติมเสร็จแล้วเด้งกลับหน้าหลัก
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to top up. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Top Up Coupons",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Amount",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "This is a mockup payment. No real money will be charged.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WithdrawPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.swap_horiz,
                        color: Color(0xFF6347EB),
                      ),
                      label: const Text(
                        "เปลี่ยนเป็น ถอนเงิน (Withdraw)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6347EB),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF6347EB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // สร้าง Grid ของปุ่มเติมเงิน
                  Expanded(
                    child: GridView.builder(
                      itemCount: _topUpAmounts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // แบ่งเป็น 2 คอลัมน์
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 2, // สัดส่วนความกว้าง:สูงของปุ่ม
                          ),
                      itemBuilder: (context, index) {
                        final amount = _topUpAmounts[index];
                        return InkWell(
                          onTap: () => _processTopUp(
                            amount,
                          ), // กดปุ๊บ เรียกฟังก์ชันหักเงินทันที
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6347EB).withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6347EB,
                                  ).withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_activity,
                                  color: Color(0xFF6347EB),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  NumberFormat('#,###').format(amount),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6347EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
