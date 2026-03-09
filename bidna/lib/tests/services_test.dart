import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:bidna/models/product_model.dart';
import 'package:bidna/services/product_service.dart';

// ─────────────────────────────────────────────────────────────────
// ProductService — pure business logic ที่ไม่ต้องใช้ Firebase จริง
// ─────────────────────────────────────────────────────────────────

ProductModel _makeProduct({
  required String status,
  required DateTime endTime,
  String highestBidderUid = '',
}) {
  return ProductModel(
    id: 'p001',
    title: 'Test',
    description: '',
    category: 'Others',
    startPrice: 100,
    currentPrice: 150,
    minBidIncrement: 10,
    images: [],
    startTime: DateTime(2025, 1, 1),
    endTime: endTime,
    status: status,
    sellerUid: 'seller-001',
    highestBidderUid: highestBidderUid.isNotEmpty ? highestBidderUid : null,
  );
}

void main() {
  group('ProductService.isAuctionEnded()', () {
    // 🔴 แก้ไข: โยน Fake เข้าไป เพื่อไม่ให้มันไปเรียก Firebase จริงจนพัง
    final fakeDb = FakeFirebaseFirestore();
    final service = ProductService(firestore: fakeDb);

    test('status = "closed" → ended', () {
      final product = _makeProduct(
        status: 'closed',
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(service.isAuctionEnded(product), isTrue);
    });

    test('status = "close" (typo variant) → ended', () {
      final product = _makeProduct(
        status: 'close',
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(service.isAuctionEnded(product), isTrue);
    });

    test('status = "CLOSED" (uppercase) → ended', () {
      final product = _makeProduct(
        status: 'CLOSED',
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(service.isAuctionEnded(product), isTrue);
    });

    test('endTime ผ่านมาแล้ว → ended แม้ status = "open"', () {
      final product = _makeProduct(
        status: 'open',
        endTime: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(service.isAuctionEnded(product), isTrue);
    });

    test('status = "open" และยังไม่หมดเวลา → not ended', () {
      final product = _makeProduct(
        status: 'open',
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(service.isAuctionEnded(product), isFalse);
    });

    test('status = "PAID" และยังไม่หมดเวลา → not ended', () {
      final product = _makeProduct(
        status: 'PAID',
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(service.isAuctionEnded(product), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ProductService — Firestore queries (ใช้ FakeFirestore)
  // ─────────────────────────────────────────────────────────────────
  group('ProductService Streams', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ProductService service; // ประกาศ service ตรงนี้

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      // 🔴 แก้ไข: สร้าง service โดยใช้ fakeFirestore ตัวเดียวกันกับที่เราจะจำลองข้อมูล
      service = ProductService(firestore: fakeFirestore);
    });

    test('getMyBidsStream คืน product ที่ userId อยู่ใน bidders', () async {
      await fakeFirestore.collection('Products').doc('p001').set({
        'title': 'Item A',
        'description': '',
        'category': 'Others',
        'startPrice': 100.0,
        'currentPrice': 200.0,
        'minBidIncrement': 10.0,
        'images': [],
        'startTime': DateTime(2025, 1, 1),
        'endTime': DateTime(2025, 12, 31),
        'status': 'open',
        'sellerUid': 'seller-001',
        'bidders': ['user-001', 'user-002'],
        'totalBids': 2,
        'isReviewed': false,
      });

      await fakeFirestore.collection('Products').doc('p002').set({
        'title': 'Item B',
        'description': '',
        'category': 'Others',
        'startPrice': 500.0,
        'currentPrice': 500.0,
        'minBidIncrement': 50.0,
        'images': [],
        'startTime': DateTime(2025, 1, 1),
        'endTime': DateTime(2025, 12, 31),
        'status': 'open',
        'sellerUid': 'seller-002',
        'bidders': ['user-003'],
        'totalBids': 1,
        'isReviewed': false,
      });

      // 🔴 แก้ไข: เปลี่ยนไปเรียกฟังก์ชัน getMyBidsStream จาก service ได้เลย
      // เพราะเราผูก fakeFirestore เข้ากับ service ไปแล้วใน setUp
      final stream = service.getMyBidsStream('user-001');

      final result = await stream.first;
      expect(result.length, 1);
      expect(result.first.title, 'Item A');
    });

    test('getMyListingsStream คืน product ของ seller', () async {
      await fakeFirestore.collection('Products').doc('p003').set({
        'title': 'My Listing',
        'description': '',
        'category': 'Electronics',
        'startPrice': 1000.0,
        'currentPrice': 1000.0,
        'minBidIncrement': 100.0,
        'images': [],
        'startTime': DateTime(2025, 1, 1),
        'endTime': DateTime(2025, 12, 31),
        'status': 'open',
        'sellerUid': 'seller-me',
        'bidders': [],
        'totalBids': 0,
        'isReviewed': false,
      });

      // 🔴 แก้ไข: เรียกฟังก์ชันจาก service แบบเนียนๆ เหมือนใช้งานจริงเลย
      final stream = service.getMyListingsStream('seller-me');

      final result = await stream.first;
      expect(result.length, 1);
      expect(result.first.sellerUid, 'seller-me');
    });
  });
}