import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/auth_result_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. ฟังก์ชันดึงข้อมูล User ปัจจุบันทั้งหมด
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 2. ฟังก์ชันดึงแค่ UID ปัจจุบัน (เขียนเพิ่มไว้ จะได้เรียกใช้ง่ายๆ ครับ)
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }


  Future<AuthResultModel> authenticateUser({
    required bool isSignIn,
    required String email,
    required String password,
    String? username, // รับ username เฉพาะตอน Sign Up
  }) async {
    try {
      UserCredential userCredential;
      if (isSignIn) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 🔴 บันทึก displayName ลง Firestore ทันทีที่สมัครสำเร็จ
        if (userCredential.user != null && username != null && username.isNotEmpty) {
          await _db.collection('Users').doc(userCredential.user!.uid).set({
            'displayName': username,
            'email': email,
            'couponBalance': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 🔴 แปลง User ของ Firebase เป็น UserModel ของเรา
      if (userCredential.user != null) {
        UserModel user = UserModel.fromFirebase(userCredential.user!);
        return AuthResultModel(user: user); // ส่งกลับว่า "สำเร็จ"
      } else {
        return AuthResultModel(errorMessage: "ไม่สามารถดึงข้อมูลผู้ใช้ได้");
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'ไม่พบผู้ใช้งานนี้';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'รหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว';
      } else {
        errorMessage = e.message ?? "เกิดข้อผิดพลาด";
      }
      return AuthResultModel(errorMessage: errorMessage); // ส่งกลับว่า "ล้มเหลว"
    } catch (e) {
      return AuthResultModel(errorMessage: "เกิดข้อผิดพลาด: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}