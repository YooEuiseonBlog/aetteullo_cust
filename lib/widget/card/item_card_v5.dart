// item_card_v5.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ItemCardV5 extends StatelessWidget {
  final String imgUrl;
  final String setNm;
  final double cnt;
  final VoidCallback? onClick;
  final VoidCallback? onImageTap;

  const ItemCardV5({
    super.key,
    required this.setNm,
    this.onClick,
    this.onImageTap,
    required this.imgUrl,
    required this.cnt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
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
                  GestureDetector(
                    onTap: onImageTap,
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                  // 이미지 하단에 반투명 흰색 오버레이: setNm 텍스트
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      color: Colors.white.withOpacity(0.85),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${cnt.toInt()}개',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── 카드 하단 여백 (필요 시 아이콘/버튼 추가 가능) ─────────────────────
            // 단순 여백만 두어 플랫한 느낌을 유지
            Container(height: 8, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
