import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  ProductDetailsPage({required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black)),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Products').doc(productId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          List images = data['images'] ?? [];
          DateTime endTime = (data['endTime'] as Timestamp).toDate();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  SizedBox(
                    height: 400,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (_, i) => Image.memory(base64Decode(images[i]), fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['category'] ?? "", style: const TextStyle(color: Color(0xFF6347EB), fontWeight: FontWeight.bold)),
                      Text(data['title'] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _info("Current Bid", "฿${NumberFormat('#,###').format(data['currentPrice'])}"),
                          _info("Ends at", DateFormat('dd MMM, HH:mm').format(endTime)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? "", style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement Bidding System
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6347EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("Place a Bid", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ]);
}