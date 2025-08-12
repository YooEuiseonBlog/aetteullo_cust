import 'package:flutter/material.dart';

/// 앱 전반의 상태를 한 곳에 모아두는 Provider
class AppStateProvider extends ChangeNotifier {
  // 1) 장바구니 수량
  int _basketCount = 0;
  int get basketCount => _basketCount;
  void setBasketCount(int count) {
    _basketCount = count;
    notifyListeners();
  }

  void addBasket(int qty) {
    _basketCount += qty;
    notifyListeners();
  }

  void removeBasket(int qty) {
    _basketCount = (_basketCount - qty).clamp(0, double.infinity).toInt();
    notifyListeners();
  }

  // 2) 알림 개수
  int _notificationCount = 0;
  int get notificationCount => _notificationCount;
  void setNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }

  void incrementNotification() {
    _notificationCount++;
    notifyListeners();
  }

  void clearNotification() {
    _notificationCount = 0;
    notifyListeners();
  }

  // 3) 하단 네비게이션 인덱스
  int _navIndex = 0;
  int get navIndex => _navIndex;
  void setNavIndex(int index) {
    _navIndex = index;
    notifyListeners();
  }
}
