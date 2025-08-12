import 'package:flutter/material.dart';

/// 재사용 가능한 모바일 스타일 카테고리 필터 칩
class MobileFilterChip extends StatelessWidget {
  /// 칩에 표시할 텍스트
  final String label;

  /// 선택 여부
  final bool selected;

  /// 선택/해제 시 호출될 콜백
  final ValueChanged<bool> onSelected;

  const MobileFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.transparent : Colors.grey.shade400,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      selected: selected,
      showCheckmark: false,
      selectedColor: Colors.green.withOpacity(0.7),
      onSelected: onSelected,
    );
  }
}
