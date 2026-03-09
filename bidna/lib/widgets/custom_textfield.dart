import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onVisibilityToggle;
  final TextEditingController? controller;
  // [เพิ่ม] ตัวแปรสำหรับรับฟังก์ชันตรวจสอบความถูกต้อง
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.isVisible = false,
    this.onVisibilityToggle,
    this.controller,
    this.validator, // [เพิ่ม]
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 8),
        // [แก้] เปลี่ยนโครงสร้างจาก Container -> TextField เป็น TextFormField โดยตรง
        // เพื่อให้ Error Message แสดงผลถูกต้องตามมาตรฐาน (ตัวแดงใต้ช่อง)
        TextFormField(
          controller: controller,
          validator: validator, // [เพิ่ม] เชื่อม validator
          obscureText: isPassword && !isVisible,
          style: const TextStyle(color: Color(0xFF2D3436)),
          autovalidateMode:
              AutovalidateMode.onUserInteraction, // เช็คทันทีที่พิมพ์เสร็จ
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA4B0BE)),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFFA4B0BE)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFFA4B0BE),
                    ),
                    onPressed: onVisibilityToggle,
                  )
                : null,
            // [Style] กำหนดเส้นขอบสถานะต่างๆ (ปกติ / error / focus)
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6C5CE7),
              ), // สีม่วงเมื่อกด
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ), // สีแดงเมื่อผิด
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
