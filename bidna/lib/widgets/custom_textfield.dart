import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onVisibilityToggle;
  final TextEditingController? controller; // [เพิ่ม] ตัวรับค่า Text

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.isVisible = false,
    this.onVisibilityToggle,
    this.controller, // [เพิ่ม]
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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDFE6E9)),
          ),
          child: TextField(
            controller: controller, // [เพิ่ม] ใส่ controller ตรงนี้
            obscureText: isPassword && !isVisible,
            style: const TextStyle(color: Color(0xFF2D3436)),
            decoration: InputDecoration(
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
