import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:bidna/models/user_model.dart';
import 'package:bidna/models/auth_result_model.dart';
import 'package:bidna/models/product_model.dart';
import 'package:bidna/models/review_model.dart';
import 'package:bidna/models/chat_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  setUp(() => fakeFirestore = FakeFirebaseFirestore());

  // 1. AuthResultModel — isSuccess ถูกต้องทั้งกรณี pass และ fail
  test('AuthResultModel: isSuccess = true เมื่อมี user / false เมื่อมี error', () {
    final mockUser = MockUser(uid: 'uid-001', email: 'a@b.com');
    final success = AuthResultModel(user: UserModel.fromFirebase(mockUser));
    final fail = AuthResultModel(errorMessage: 'ไม่พบผู้ใช้');

    expect(success.isSuccess, isTrue);
    expect(fail.isSuccess, isFalse);
    expect(fail.errorMessage, 'ไม่พบผู้ใช้');
  });

  // 2. ProductModel — fromDoc ครบ field
  test('ProductModel.fromDoc: map ครบทุก field', () async {
    await fakeFirestore.collection('Products').doc('p001').set({
      'title': 'Vintage Watch',
      'description': 'Rare',
      'category': 'Collectibles',
      'startPrice': 1000.0,
      'currentPrice': 1500.0,
      'minBidIncrement': 100.0,
      'images': ['img1', 'img2'],
      'startTime': DateTime(2025, 1, 1),
      'endTime': DateTime(2025, 12, 31),
      'status': 'open',
      'sellerUid': 'seller-001',
      'highestBidderUid': 'bidder-001',
      'totalBids': 3,
      'bidders': ['b1', 'b2'],
      'isReviewed': false,
    });
    final doc = await fakeFirestore.collection('Products').doc('p001').get();
    final p = ProductModel.fromDoc(doc);

    expect(p.title, 'Vintage Watch');
    expect(p.currentPrice, 1500.0);
    expect(p.images.length, 2);
    expect(p.highestBidderUid, 'bidder-001');
    expect(p.totalBids, 3);
  });

  // 3. ProductModel — default values เมื่อ Firestore ไม่ครบ field
  test('ProductModel.fromDoc: ใช้ default เมื่อ field หาย', () async {
    await fakeFirestore.collection('Products').doc('p002').set({'title': 'X'});
    final doc = await fakeFirestore.collection('Products').doc('p002').get();
    final p = ProductModel.fromDoc(doc);

    expect(p.category, 'Others');
    expect(p.status, 'open');
    expect(p.images, isEmpty);
    expect(p.totalBids, 0);
  });

  // 4. ReviewModel — toMap ครอบคลุม field ที่ส่งไป Firestore
  test('ReviewModel.toMap: มี field ครบที่จำเป็น', () {
    final review = ReviewModel(
      reviewId: '',
      reviewerId: 'u001',
      reviewerName: 'Alice',
      sellerId: 's001',
      productId: 'p001',
      productTitle: 'Watch',
      rating: 5.0,
      comment: 'Great!',
      createdAt: DateTime.now(),
    );
    final map = review.toMap();

    expect(map['reviewerId'], 'u001');
    expect(map['rating'], 5.0);
    expect(map['comment'], 'Great!');
    expect(map.containsKey('createdAt'), isTrue);
  });

  // 5. ChatRoomModel — sort logic: room ที่มี lastTimestamp ใหม่กว่าต้องอยู่ก่อน
  test('ChatRoomModel: sort ตาม lastTimestamp descending', () async {
    await fakeFirestore.collection('ChatRooms').doc('old').set({
      'users': ['a', 'b'], 'lastMessage': 'old',
      'lastTimestamp': DateTime(2025, 1, 1),
    });
    await fakeFirestore.collection('ChatRooms').doc('new').set({
      'users': ['a', 'c'], 'lastMessage': 'new',
      'lastTimestamp': DateTime(2025, 6, 1),
    });

    final snap = await fakeFirestore.collection('ChatRooms').get();
    final rooms = snap.docs.map((d) => ChatRoomModel.fromDoc(d)).toList();
    rooms.sort((a, b) {
      if (a.lastTimestamp == null) return 1;
      if (b.lastTimestamp == null) return -1;
      return b.lastTimestamp!.compareTo(a.lastTimestamp!);
    });

    expect(rooms.first.lastMessage, 'new');
    expect(rooms.last.lastMessage, 'old');
  });

  // 6. MessageModel — text และ image message
  test('MessageModel.fromDoc: map text และ image message ได้ถูกต้อง', () async {
    final col = fakeFirestore.collection('ChatRooms').doc('r1').collection('messages');
    await col.doc('m1').set({
      'senderId': 'uid-A', 'receiverId': 'uid-B',
      'text': 'Hello!', 'image': null, 'timestamp': DateTime(2025, 6, 1),
    });
    await col.doc('m2').set({
      'senderId': 'uid-B', 'receiverId': 'uid-A',
      'text': null, 'image': 'base64data', 'timestamp': DateTime(2025, 6, 1),
    });

    final m1 = MessageModel.fromDoc(await col.doc('m1').get());
    final m2 = MessageModel.fromDoc(await col.doc('m2').get());

    expect(m1.text, 'Hello!');
    expect(m1.image, isNull);
    expect(m2.text, isNull);
    expect(m2.image, 'base64data');
  });

  // 7. UserModel — map จาก Firebase ได้ถูกต้อง
  // NOTE: signup_page เรียกแค่ result.isSuccess / result.errorMessage
  //       ไม่เคยแตะ result.user โดยตรง → UserModel เป็น dead code ในฝั่ง UI
  test('UserModel.fromFirebase: map UID และ email ได้ถูกต้อง', () {
    final mockUser = MockUser(uid: 'uid-999', email: 'hello@bidna.com');
    final model = UserModel.fromFirebase(mockUser);

    expect(model.uid, 'uid-999');
    expect(model.email, 'hello@bidna.com');
  });
}