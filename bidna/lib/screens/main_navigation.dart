import 'package:flutter/material.dart';
import 'package:bidna/screens/HomeScreen.dart';
import '../screens/create_list_page.dart';
import '../screens/profile_page.dart';
import '../screens/my_bid_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // เพิ่มหน้าลงไปใน List ให้ครบ 5 หน้าตรงกับไอคอนด้านล่าง
  final List<Widget> _pages = [
    const HomeScreen(),
    CreateListingBase64(),
    const Center(child: Text("หน้า Chat", style: TextStyle(fontSize: 24))),
    const MyBidPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF6347EB), // สีม่วงธีมแอป
        unselectedItemColor: Colors.grey,
        // สำคัญมาก: เมื่อมีไอเทมมากกว่า 3 อัน ต้องใส่ type เป็น fixed เพื่อให้โชว์ครบทุกตัวและสีไม่เพี้ยน
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore), 
            label: 'Explore'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle), 
            label: 'Create'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline), 
            label: 'Chat'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel), // ใช้ไอคอนค้อนประมูลให้เข้ากับ MyBid
            label: 'MyBid'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            label: 'Profile'
          ),
        ],
      ),
    );
  }
}