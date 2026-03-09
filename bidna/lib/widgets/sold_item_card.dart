import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bidna/models/product_model.dart';

class SoldItemCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const SoldItemCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageBase64 =
        product.images.isNotEmpty ? product.images[0] : null;
    final String priceFormatted =
        NumberFormat('#,###').format(product.currentPrice);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: imageBase64 != null
                  ? Image.memory(
                      base64Decode(imageBase64),
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 95,
                      color: const Color(0xFFF0EDFF),
                      child: const Center(
                        child: Icon(Icons.image, color: Color(0xFF6347EB)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '฿$priceFormatted',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6347EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}