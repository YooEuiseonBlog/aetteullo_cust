// item_card_v5.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ItemCardV5 extends StatelessWidget {
  final String imgUrl;
  final String setNm;
  final double cnt;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ItemCardV5({
    super.key,
    required this.setNm,
    this.onTap,
    required this.imgUrl,
    required this.cnt,
    this.onLongPress,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        // 플랫 디자인: 그림자 없이 연한 회색 테두리와 둥근 모서리
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 이미지 전체 채우기 & 텍스트 오버레이 ─────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 배경 이미지
                  CachedNetworkImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  // 이미지 하단에 반투명 흰색 오버레이: setNm 텍스트
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      color: Colors.white.withValues(alpha: 0.85),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            setNm,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${cnt.toInt()}개',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
