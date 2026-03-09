import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';

// -----------------------------------------------------------------
// 🌟 1. การ์ดสำหรับ "ผู้ชนะ" (มี Effect พลุ และปุ่มจ่ายเงิน)
// -----------------------------------------------------------------
class WinnerActionCard extends StatefulWidget {
  final double winningPrice;
  final VoidCallback onPayPressed;

  const WinnerActionCard({super.key, required this.winningPrice, required this.onPayPressed});

  @override
  State<WinnerActionCard> createState() => _WinnerActionCardState();
}

class _WinnerActionCardState extends State<WinnerActionCard> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // ตั้งค่า Controller สำหรับพลุ และสั่งให้ยิงทันทีที่หน้านี้เปิดขึ้นมา
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play(); 
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // ตัวพลุที่จะยิงออกมา
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive, // ยิงกระจายทุกทิศทาง
          shouldLoop: false,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
        
        // UI กล่องข้อความผู้ชนะ
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300, width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.orange, size: 48),
              const SizedBox(height: 8),
              const Text(
                "🎉 ยินดีด้วย! คุณคือผู้ชนะการประมูล 🎉",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                "ยอดชำระ: ฿${NumberFormat('#,###').format(widget.winningPrice)}",
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onPayPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("ยืนยันการชำระเงิน", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// 🌟 2. การ์ดสำหรับ "คนอื่นๆ" หรือ "ผู้แพ้"
// -----------------------------------------------------------------
class EndedActionCard extends StatelessWidget {
  const EndedActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(Icons.timer_off, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text(
            "การประมูลสิ้นสุดลงแล้ว",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            "ขอขอบคุณที่ให้ความสนใจ",
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// 🌟 3. การ์ดสำหรับ "ผู้ชนะที่จ่ายเงินแล้ว" (รอรับสินค้า)
// -----------------------------------------------------------------
class ConfirmReceiptCard extends StatelessWidget {
  final VoidCallback onConfirmPressed;

  const ConfirmReceiptCard({super.key, required this.onConfirmPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 48),
          const SizedBox(height: 8),
          const Text(
            "ชำระเงินเรียบร้อยแล้ว",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          const Text(
            "ระบบกำลังระงับ Coupon ของคุณไว้\nกรุณากดปุ่มด้านล่างเมื่อคุณ 'ได้รับสินค้าแล้ว' เพื่อโอน Coupon ให้กับผู้ขาย",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirmPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("ฉันได้รับสินค้าแล้ว", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// 🌟 4. การ์ด "ออเดอร์สำเร็จ" (ผู้ซื้อรับของแล้ว ผู้ขายได้เงินแล้ว)
// -----------------------------------------------------------------
class OrderCompletedCard extends StatelessWidget {
  const OrderCompletedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade400, width: 2),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(height: 8),
          Text(
            "ออเดอร์นี้เสร็จสมบูรณ์",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          SizedBox(height: 4),
          Text(
            "ผู้ขายได้รับ Coupon เรียบร้อยแล้ว",
            style: TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}