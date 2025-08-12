import 'package:flutter/material.dart';

/// 버튼의 모드를 정의하는 enum
enum ButtonMode { success, alert }

class GradientButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final double bordRadius;
  final ButtonMode mode; // mode 파라미터 추가

  const GradientButton({
    super.key,
    required this.title,
    required this.onTap,
    this.bordRadius = 8,
    this.mode = ButtonMode.success, // 기본값은 success
  });

  /// mode에 따라 적절한 그라데이션을 반환합니다.
  LinearGradient _buildGradient() {
    switch (mode) {
      case ButtonMode.alert:
        return const LinearGradient(
          colors: [
            Color(0xFFFF5C5C), // 밝은 빨강
            Color(0xFFE60000), // 진한 빨강
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case ButtonMode.success:
        return const LinearGradient(
          colors: [Color(0XFF61D373), Color(0XFF0CC277)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: _buildGradient(),
          borderRadius: BorderRadius.circular(bordRadius),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
