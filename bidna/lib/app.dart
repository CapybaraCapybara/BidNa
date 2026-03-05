import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bidna/screens/login_screen.dart';
import 'package:bidna/screens/main_navigation.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bidna',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromRGBO(238, 237, 237, 1),
      ),
      // ดักจับสถานะ Login สดๆ จาก Firebase
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // ถ้ามีข้อมูล User (ล็อกอินแล้ว) ให้ไปหน้า MainNavigation
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          // ถ้ายังไม่ล็อกอิน ให้ไปหน้า Login
          return const LoginScreen();
        },
      ),
    );
  }
}