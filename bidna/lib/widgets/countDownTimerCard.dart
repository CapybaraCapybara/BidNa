import 'dart:async';
import 'package:flutter/material.dart';

class AuctionCountdownCard extends StatefulWidget {
  final DateTime endTime;

  const AuctionCountdownCard({super.key, required this.endTime});

  @override
  State<AuctionCountdownCard> createState() => _AuctionCountdownCardState();
}

class _AuctionCountdownCardState extends State<AuctionCountdownCard> {
  Timer? _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    // สร้าง Timer ให้นับถอยหลังทุกวินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
      }
    });
  }

  void _calculateRemainingTime() {
    _remainingTime = widget.endTime.difference(DateTime.now());
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // สำคัญมาก: ต้องคืน Memory เมื่อ Widget ถูกลบ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logic การเปลี่ยนสี: ถ้าเหลือน้อยกว่า 10 นาที ให้กลายเป็นสีแดงอ่อน
    bool isUrgent =
        _remainingTime.inMinutes < 10 && _remainingTime.inSeconds > 0;

    Color backgroundColor = isUrgent
        ? const Color(0xFFFFF0F0)
        : const Color(0xFFF0F5F9);
    Color contentColor = isUrgent ? Colors.redAccent : const Color(0xFF5E6E82);

    String hours = _remainingTime.inHours.toString().padLeft(2, '0');
    String minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: contentColor, size: 20),
          const SizedBox(width: 16),
          _buildTimeColumn(hours, "H", contentColor),
          _buildDivider(contentColor),
          _buildTimeColumn(minutes, "M", contentColor),
          _buildDivider(contentColor),
          _buildTimeColumn(seconds, "S", contentColor),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String value, String unit, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(color: color.withOpacity(0.6), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        ":",
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
