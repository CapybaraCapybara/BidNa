import 'package:flutter/material.dart';

/// Widget แสดงดาว 5 ดาวให้กดเลือกคะแนน
class StarRatingWidget extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: index < rating
                ? const Color(0xFFFFC107)
                : Colors.grey.shade300,
            size: 40,
          ),
          onPressed: () => onRatingChanged(index + 1.0),
        );
      }),
    );
  }
}