import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // [เพิ่ม]
import 'screens/login_screen.dart';
import 'firebase_options.dart'; // [ต้องมีไฟล์นี้จากการ setup firebase cli]

void main() async {
  // [แก้] เป็น async
  WidgetsFlutterBinding.ensureInitialized(); // [เพิ่ม]
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // [เพิ่ม] ใช้ options ที่ generate มา
  );  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BidNa Login',
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
      ),
      home: const LoginScreen(),
    );
  }
}
