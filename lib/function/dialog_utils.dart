import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 앱 종료 전 사용자에게 확인 다이얼로그를 띄워 종료 여부를 반환합니다.
/// Navigator 스택에 pop할 화면이 없을 경우, 사용자에게 종료 여부를 묻고,
/// 사용자가 종료를 선택하면 [onExit] 콜백을 실행한 후 앱을 종료합니다.
Future<bool> showExitConfirmDialog(
  BuildContext context, {
  Future<void> Function()? onExit,
  String? title,
  String? content,
  String? cancelBtn,
  String? submitBtn,
  bool onOff = false,
}) async {
  if (Navigator.of(context).canPop()) {
    return true;
  } else {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? '앱 종료'),
        content: Text(content ?? '앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelBtn ?? '취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(submitBtn ?? '종료'),
          ),
        ],
      ),
    );
    if (result == true) {
      if (onExit != null) {
        await onExit();
      }
      if (onOff) {
        SystemNavigator.pop();
      }
      return true;
    }
    return false;
  }
}
