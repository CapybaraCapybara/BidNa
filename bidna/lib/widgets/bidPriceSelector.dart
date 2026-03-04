import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class BidActionCard extends StatefulWidget {
  final double currentPrice;
  final int bidCount;
  final double minBidIncrement; // [เพิ่ม] รับค่าบิดขั้นต่ำจาก Database
  final Function(double) onBidPlaced;
  final DateTime endTime;

  const BidActionCard({
    super.key,
    required this.currentPrice,
    this.bidCount = 0,
    required this.minBidIncrement, // [เพิ่ม]
    required this.onBidPlaced,
    required this.endTime,
  });

  @override
  State<BidActionCard> createState() => _BidActionCardState();
}

class _BidActionCardState extends State<BidActionCard> {
  final TextEditingController _bidController = TextEditingController();
  Timer? _timer;
  bool _isEnded = false;

  @override
  void initState() {
    super.initState();
    _checkTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTime();
    });
  }

  void _checkTime() {
    bool ended = DateTime.now().isAfter(widget.endTime);
    if (ended != _isEnded) {
      if (mounted) {
        setState(() {
          _isEnded = ended;
        });
      }
      if (ended) _timer?.cancel(); 
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. ส่วนแสดงราคาปัจจุบันและจำนวนครั้งที่ประมูล (ดึงค่าจริงมาแสดง)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceInfo("Current Bid", widget.currentPrice),
              Text(
                '${widget.bidCount} Bids',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // (นำส่วนปุ่มลัดเพิ่มราคาด่วนออกชั่วคราวตามที่ต้องการ)

          // 2. ส่วนช่องกรอกราคาและปุ่ม Place Bid
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bidController,
                  enabled: !_isEnded,
                  decoration: InputDecoration(
                    hintText: "Enter amount",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isEnded
                    ? null
                    : () {
                        double bidAmount =
                            double.tryParse(_bidController.text) ?? 0;
                        widget.onBidPlaced(bidAmount);
                        _bidController.clear(); // เคลียร์ช่องให้หลังจากกดประมูล
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(96, 103, 237, 1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Place Bid",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. แสดงราคาขั้นต่ำ (คำนวณจากราคาปัจจุบัน + บิดขั้นต่ำ)
          Text(
            'Minimum bid: ฿${NumberFormat('#,###').format(widget.currentPrice + widget.minBidIncrement)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Widget ย่อยสำหรับแสดงหัวข้อและตัวเลขราคา
  Widget _buildPriceInfo(String label, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          "฿${NumberFormat('#,###').format(price)}",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(96, 103, 237, 1),
          ),
        ),
      ],
    );
  }
}