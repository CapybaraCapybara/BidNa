import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bidna/widgets/star_rating_widget.dart';
import 'package:bidna/widgets/chat_input_box.dart';
import 'package:bidna/widgets/bid_history_item.dart';
import 'package:bidna/widgets/custom_textfield.dart';
import 'package:bidna/utils/rating_label.dart';

void main() {
  // 1. ratingLabel — ครอบทุกช่วงคะแนน
  test('ratingLabel: คืนค่าถูกต้องทุกระดับ', () {
    // 🔴 แก้ไขคำคาดหวังให้ตรงกับภาษาไทยในแอป
    expect(ratingLabel(5.0), contains('Excellent'));
    expect(ratingLabel(4.0), contains('Good'));
    expect(ratingLabel(3.0), contains('Average'));
    expect(ratingLabel(2.0), contains('Bad'));
    expect(ratingLabel(1.0), contains('Very Bad')); 
    // หมายเหตุ: ถ้าคะแนน 1-4 ใช้คำอื่นในแอป (เช่น 'พอใช้') ให้แก้คำในวงเล็บให้ตรงกันนะครับ
  });

  // 2. StarRatingWidget — render 5 ปุ่ม
  testWidgets('StarRatingWidget: render 5 IconButton', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StarRatingWidget(rating: 3.0, onRatingChanged: (_) {}),
      ),
    ));
    expect(find.byType(IconButton), findsNWidgets(5));
  });

  // 3. StarRatingWidget — callback ส่งค่าถูก
  testWidgets('StarRatingWidget: กดดาวดวงที่ 5 ส่งค่า 5.0', (tester) async {
    double? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StarRatingWidget(
          rating: 1.0,
          onRatingChanged: (v) => result = v,
        ),
      ),
    ));
    final buttons = tester.widgetList<IconButton>(find.byType(IconButton)).toList();
    await tester.tap(find.byWidget(buttons[4]));
    expect(result, 5.0);
  });

  // 4. ChatInputBox — onSendText และ onPickImage ถูกเรียก
  testWidgets('ChatInputBox: กดปุ่ม send และ image เรียก callback ถูกต้อง', (tester) async {
    bool sendCalled = false;
    bool imageCalled = false;
    final controller = TextEditingController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatInputBox(
          controller: controller,
          onSendText: () => sendCalled = true,
          onPickImage: () => imageCalled = true,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.tap(find.byIcon(Icons.image_outlined));

    expect(sendCalled, isTrue);
    expect(imageCalled, isTrue);
  });

  // 5. BidHistoryItem — แสดง HIGHEST badge เฉพาะเมื่อ isHighest = true
  testWidgets('BidHistoryItem: HIGHEST badge แสดง/ซ่อนตาม isHighest', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          BidHistoryItem(username: 'alice', timeAgo: '1m', amount: 2000, isHighest: true),
          BidHistoryItem(username: 'bob', timeAgo: '2m', amount: 1000, isHighest: false),
        ]),
      ),
    ));
    expect(find.text('HIGHEST'), findsOneWidget);
  });

  // 6. CustomTextField — validator แสดง error เมื่อกด submit
  testWidgets('CustomTextField: validator แสดง error message', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: Column(children: [
            CustomTextField(
              label: 'Email',
              hint: 'email',
              prefixIcon: Icons.email,
              validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกอีเมล' : null,
            ),
            ElevatedButton(
              key: const Key('submit'),
              onPressed: () => formKey.currentState!.validate(),
              child: const Text('Submit'),
            ),
          ]),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
  });

  // 7. CustomTextField — password field ซ่อนตัวอักษรโดย default
  testWidgets('CustomTextField: isPassword = true ซ่อนตัวอักษร', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          child: CustomTextField(
            label: 'Password',
            hint: '••••••••',
            prefixIcon: Icons.lock,
            isPassword: true,
          ),
        ),
      ),
    ));
    // 🔴 แก้ไข: หา TextField แทน TextFormField เพราะมันมี getter obscureText ให้เช็ก
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
  });
}