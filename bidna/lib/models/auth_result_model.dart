import 'user_model.dart';

class AuthResultModel {
  final UserModel? user;
  final String? errorMessage;

  AuthResultModel({this.user, this.errorMessage});

  // ตัวช่วยเช็คว่าทำงานสำเร็จหรือไม่
  bool get isSuccess => user != null && errorMessage == null;
}