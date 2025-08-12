import 'package:flutter/material.dart';

/// 재사용 가능한 모바일 스타일 Chip
class MobileChip extends StatelessWidget {
  /// Chip에 표시할 텍스트
  final String label;

  /// 삭제(닫기) 버튼이 눌렸을 때 호출되는 콜백
  final VoidCallback? onDeleted;

  const MobileChip({super.key, required this.label, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      deleteIcon: const Icon(Icons.close, size: 18),
      deleteIconColor: Colors.black,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onDeleted: onDeleted,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
