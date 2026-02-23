import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BidActionCard extends StatefulWidget {
  final double currentPrice;
  final int bidCount;
  final Function(double) onBidPlaced;

  const BidActionCard({
    super.key,
    required this.currentPrice,
    this.bidCount = 0,
    required this.onBidPlaced,
  });

  @override
  State<BidActionCard> createState() => _BidActionCardState();
}

class _BidActionCardState extends State<BidActionCard> {
  final TextEditingController _bidController = TextEditingController();

  @override
  void dispose() {
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
          // 1. ส่วนแสดงราคาปัจจุบันและจำนวนครั้งที่ประมูล
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

          // 2. ส่วนปุ่มลัดเพิ่มราคา (+50, +100, +150)
          Row(
            children: [
              _buildQuickBidButton(50),
              const SizedBox(width: 8),
              _buildQuickBidButton(100),
              const SizedBox(width: 8),
              _buildQuickBidButton(150),
            ],
          ),
          const SizedBox(height: 16),

          // 3. ส่วนช่องกรอกราคาและปุ่ม Place Bid
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bidController,
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
                onPressed: () {
                  double bidAmount = double.tryParse(_bidController.text) ?? 0;
                  widget.onBidPlaced(bidAmount);
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

          // 4. แสดงราคาขั้นต่ำ
          Text(
            'Minimum bid: ฿${NumberFormat('#,###').format(widget.currentPrice + 50)}',
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Widget ย่อยสำหรับปุ่มเพิ่มราคาด่วน
  Widget _buildQuickBidButton(double extra) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _bidController.text = (widget.currentPrice + extra).toStringAsFixed(
              0,
            );
          });
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
        child: Text(
          "+฿${extra.toInt()}",
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
