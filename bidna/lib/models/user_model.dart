import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? email;

  UserModel({
    required this.uid,
    this.email,
  });

  // Factory Constructor ช่วยแปลงข้อมูลจาก Firebase มาเป็น Model ของเรา
  factory UserModel.fromFirebase(User firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
    );
  }
}