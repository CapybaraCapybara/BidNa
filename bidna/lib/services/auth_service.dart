import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/auth_result_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AuthResultModel> authenticateUser({
    required bool isSignIn,
    required String email,
    required String password,
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