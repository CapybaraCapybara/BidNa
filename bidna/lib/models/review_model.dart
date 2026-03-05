import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String reviewerId;     // UID คนรีวิว (ผู้ชนะประมูล)
  final String reviewerName;
  final String? reviewerImage; // base64
  final String sellerId;       // UID คนขาย (เจ้าของสินค้า)
  final String productId;      // สินค้าที่ถูกรีวิว
  final String productTitle;
  final double rating;         // 1.0 – 5.0
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImage,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      reviewId:      doc.id,
      reviewerId:    d['reviewerId']    ?? '',
      reviewerName:  d['reviewerName']  ?? 'Anonymous',
      reviewerImage: d['reviewerImage'],
      sellerId:      d['sellerId']      ?? '',
      productId:     d['productId']     ?? '',
      productTitle:  d['productTitle']  ?? '',
      rating:        (d['rating']       ?? 0).toDouble(),
      comment:       d['comment']       ?? '',
      createdAt:     (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'reviewerId':    reviewerId,
    'reviewerName':  reviewerName,
    'reviewerImage': reviewerImage,
    'sellerId':      sellerId,
    'productId':     productId,
    'productTitle':  productTitle,
    'rating':        rating,
    'comment':       comment,
    'createdAt':     FieldValue.serverTimestamp(),
  };
}