import 'package:flutter/material.dart';
import 'package:bidna/screens/HomeScreen.dart';
import 'package:bidna/screens/login_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isLoggedIn = false;
  int _selectedIndex = 0;

  // 2. รายชื่อหน้าต่างๆ (เรียงตามไอคอนข้างล่าง)
  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text("หน้า Sell")),
    const Center(child: Text("หน้า Watchlist")),
    const Center(child: Text("หน้า Profile")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

      home: _isLoggedIn
          ? Scaffold(
              body: _pages[_selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart),
                    label: 'Sell',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Watchlist',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            )
          : const LoginScreen(),
    );
  }
}
