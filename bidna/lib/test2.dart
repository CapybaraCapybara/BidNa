import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // ไฟล์นี้ต้องได้มาจากการรัน flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const FirestoreDemo(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class FirestoreDemo extends StatefulWidget {
  const FirestoreDemo({super.key});

  @override
  State<FirestoreDemo> createState() => _FirestoreDemoState();
}

class _FirestoreDemoState extends State<FirestoreDemo> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. ฟังก์ชันบันทึกข้อมูลแบบกำหนด ID เอง (Primary Key)
  Future<void> _addData() async {
    String customUserId = "user_001"; // นี่คือ Primary Key ที่เรากำหนดเอง

    // บันทึกข้อมูล User
    await _firestore.collection('users').doc(customUserId).set({
      'name': 'Somchai Dev',
      'email': 'somchai@example.com',
    });

    // บันทึกข้อมูล Order โดยอ้างอิงถึง userId (เหมือน Foreign Key)
    await _firestore.collection('orders').add({
      'ownerId': customUserId, // เก็บ ID ของ user ไว้เพื่อเชื่อมโยง
      'item': 'MacBook Pro M3',
      'price': 79900,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore PK & Relation')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addData,
            child: const Text('1. กดเพื่อบันทึกข้อมูล (User + Order)'),
          ),
          const Divider(),
          const Text('รายการออเดอร์ในระบบ:', style: TextStyle(fontWeight: FontWeight.bold)),
          
          // 2. ส่วนการแสดงผลข้อมูล (ดึงจากคอลเลกชัน orders)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text(data['item']),
                      subtitle: Text('สั่งซื้อโดย ID: ${data['ownerId']}'), // แสดงค่าที่เชื่อมโยงกัน
                      trailing: Text('${data['price']} บาท'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}