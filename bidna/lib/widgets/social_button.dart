import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final Widget
  icon; // เปลี่ยนรับเป็น Widget เพื่อความยืดหยุ่น (ใส่ Image หรือ Icon ก็ได้)
  final VoidCallback onTap;

  const SocialButton({Key? key, required this.icon, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDFE6E9)), // Border Grey
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
