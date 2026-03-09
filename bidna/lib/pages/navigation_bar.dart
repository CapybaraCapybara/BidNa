import 'package:flutter/material.dart';
import 'package:bidna/pages/explore_page.dart';
import 'create_list_page.dart';
import 'my_bid_page.dart';
import 'chat_list_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    CreateListingBase64(),
    const ChatListPage(),
    const MyBidPage(),
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
        selectedItemColor: const Color(0xFF6347EB),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, 
        // แก้ไข items ให้เหลือ 4 อัน
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
            icon: Icon(Icons.gavel), 
            label: 'MyBid'
          ),
        ],
      ),
    );
  }
}