import 'package:flutter/material.dart';

/// 재사용 가능한 필터 바
/// [chips]: 왼쪽에 표시할 Chip 위젯 리스트
/// [onFilterTap]: 우측 필터 아이콘 클릭 콜백
class FilterBar extends StatelessWidget {
  final List<Widget> chips;
  final VoidCallback onFilterTap;
  final double height;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const FilterBar({
    super.key,
    required this.chips,
    required this.onFilterTap,
    this.height = 48.0,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      height: height,
      padding: padding,
      child: Row(
        children: [
          // 가로 스크롤 가능한 Chip 리스트
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ),

          const SizedBox(width: 10),

          // 필터 아이콘
          InkWell(
            onTap: onFilterTap,
            child: const Icon(Icons.tune, size: 24, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
