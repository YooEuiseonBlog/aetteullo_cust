import 'package:flutter/material.dart';

/// 주문 정보 필드 위젯 클래스 (라벨과 값을 좌우로 배치)
class InfoField extends StatelessWidget {
  final dynamic label;
  final dynamic value;
  final bool removeUnderline;
  final FontWeight? fontWeight;

  const InfoField({
    super.key,
    required this.label,
    required this.value,
    this.removeUnderline = false,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: removeUnderline
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              color: Colors.white,
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // 세로 방향 정렬
        children: [
          // 라벨
          label is String
              ? Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                )
              : label,
          // 값
          value is String
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: fontWeight ?? FontWeight.normal,
                  ),
                  // 여러 줄로 표시
                  softWrap: true,
                  maxLines: 3, // 필요 시 더 늘릴 수 있음
                  overflow: TextOverflow.ellipsis,
                )
              : value,
        ],
      ),
    );
  }
}
