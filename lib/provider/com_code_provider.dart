import 'package:flutter/material.dart';

class ComCodeProvider extends ChangeNotifier {
  // 내부 저장소
  final Map<String, List<Map<String, dynamic>>> _comCodes = {};

  // 외부 읽기 전용 접근자
  Map<String, List<Map<String, dynamic>>> get comCodes => _comCodes;

  /// 전체 공통코드를 한 번에 교체
  void setComCodes(Map<String, List<Map<String, dynamic>>> codes) {
    _comCodes
      ..clear()
      ..addAll(codes);
    notifyListeners();
  }

  /// 특정 그룹 전체를 설정(없으면 생성)
  void setGroup(
    String groupKey,
    Map<String, List<Map<String, dynamic>>> groupCodes,
  ) {
    _comCodes[groupKey] = groupCodes[groupKey] ?? [];
    notifyListeners();
  }

  /// 특정 그룹 제거
  void removeGroup(String groupKey) {
    if (_comCodes.remove(groupKey) != null) {
      notifyListeners();
    }
  }
}
