import 'package:flutter/material.dart';
import 'package:bidna/screens/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // ต้องมี MaterialApp ครอบเป็นตัวแม่สุดเสมอ
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bidna',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromRGBO(238, 237, 237, 1),
      ),
      // กำหนดให้หน้าแรกของแอปคือ LoginScreen
      home: const LoginScreen(),
    );
  }
}