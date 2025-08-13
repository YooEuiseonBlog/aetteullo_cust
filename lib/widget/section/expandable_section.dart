import 'package:flutter/material.dart';

/// 확장/접힘 가능한 섹션 위젯 (ExpandableSection)
class ExpandableSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final Alignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.children,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias, // 내부 자식이 borderRadius 범위를 넘지 않도록 클립
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 기본 구분선 제거
        ),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          childrenPadding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          iconColor: Colors.grey.withOpacity(0.7),
          collapsedIconColor: Colors.grey.withOpacity(0.7),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          expandedAlignment: mainAxisAlignment ?? Alignment.centerLeft,
          expandedCrossAxisAlignment: crossAxisAlignment,
          children: children,
        ),
      ),
    );
  }
}
