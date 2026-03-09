import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double startPrice;
  final double currentPrice;
  final double minBidIncrement;
  final List<String> images;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String sellerUid;
  final String? highestBidderUid;
  final int totalBids;
  final List<String> bidders;
  final bool isReviewed;
  final String? reviewedBy;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startPrice,
    required this.currentPrice,
    required this.minBidIncrement,
    required this.images,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.sellerUid,
    this.highestBidderUid,
    this.totalBids = 0,
    this.bidders = const [],
    this.isReviewed = false,
    this.reviewedBy,
  });

  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'Others',
      startPrice: (d['startPrice'] ?? 0).toDouble(),
      currentPrice: (d['currentPrice'] ?? 0).toDouble(),
      minBidIncrement: (d['minBidIncrement'] ?? 1).toDouble(),
      images: List<String>.from(d['images'] ?? []),
      startTime: (d['startTime'] as Timestamp?)
              ?.toDate()
              .toLocal() ??
          DateTime.now(),
      endTime: (d['endTime'] as Timestamp?)
              ?.toDate()
              .toLocal() ??
          DateTime.now(),
      status: d['status'] ?? 'open',
      sellerUid: d['sellerUid'] ?? '',
      highestBidderUid: d['highestBidderUid'],
      totalBids: (d['totalBids'] ?? 0).toInt(),
      bidders: List<String>.from(d['bidders'] ?? []),
      isReviewed: d['isReviewed'] ?? false,
      reviewedBy: d['reviewedBy'],
    );
  }
}