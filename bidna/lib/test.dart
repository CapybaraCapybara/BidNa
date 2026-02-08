import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // ไฟล์ที่ได้จากการรัน 'flutterfire configure'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // เริ่มต้นใช้งาน Firebase
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
      title: 'Flutter Firestore Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const FirestoreScreen(),
    );
  }
}

class FirestoreScreen extends StatefulWidget {
  const FirestoreScreen({super.key});

  @override
  State<FirestoreScreen> createState() => _FirestoreScreenState();
}

class _FirestoreScreenState extends State<FirestoreScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');

  // ฟังก์ชันบันทึกข้อมูล (CREATE)
  Future<void> _addUser() async {
    if (_controller.text.isNotEmpty) {
      await _users.add({
        'name': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Note App')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'ใส่ชื่อหรือข้อความ'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addUser,
                ),
              ],
            ),
          ),
          const Divider(),
          const Text("รายการข้อมูลจาก Firebase:", style: TextStyle(fontWeight: FontWeight.bold)),
          // ส่วนดึงข้อมูลมาแสดงผล (READ - Realtime)
          Expanded(
            child: StreamBuilder(
              stream: _users.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) return const Center(child: Text('เกิดข้อผิดพลาด'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? 'ไม่มีชื่อ'),
                      subtitle: Text(data['timestamp']?.toDate().toString() ?? 'กำลังบันทึก...'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _users.doc(doc.id).delete(), // แถม: ฟังก์ชันลบ
                      ),
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