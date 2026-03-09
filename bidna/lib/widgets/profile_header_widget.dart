import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String displayName;
  final String phoneNumber;
  final String bio;
  final String? base64Image;
  final double rating;
  final int ratingCount;

  const ProfileHeaderWidget({
    super.key,
    required this.displayName,
    required this.phoneNumber,
    required this.bio,
    this.base64Image,
    required this.rating,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (base64Image != null && base64Image!.isNotEmpty)
                ? MemoryImage(base64Decode(base64Image!))
                : null,
            child: (base64Image == null || base64Image!.isEmpty)
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (phoneNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_iphone, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    phoneNumber,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 20),
              const SizedBox(width: 4),
              Text(
                '${ratingCount > 0 ? rating.toStringAsFixed(1) : "N/A"} ($ratingCount reviews)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bio.isNotEmpty)
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
        ],
      ),
    );
  }
}