import 'package:aetteullo_cust/provider/model/user.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  User _user;

  /// 기본 생성자: user가 주어지지 않으면 empty로 초기화
  UserProvider([User? user]) : _user = user ?? User.empty();

  /// 현재 사용자
  User get user => _user;

  /// 사용자 정보가 비어 있는지
  bool get isEmpty => _user.isEmpty;

  /// 사용자 정보를 업데이트하고 구독 위젯에 알림
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}
