// lib/component/card/check_item_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CheckItemCardV3 extends StatelessWidget {
  final String itemName;
  final int qty;
  final String imageUrl;
  final bool isSelected; // 외부에서 전달받는 선택 상태
  final ValueChanged<bool> onSelected; // 선택 토글 시 부모에게 알리는 콜백

  const CheckItemCardV3({
    super.key,
    required this.itemName,
    required this.qty,
    required this.imageUrl,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected(!isSelected); // 현재 상태의 반대값을 부모에 전달
      },
      child: Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) Background image
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (c, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (c, url, e) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),

            // 2) Optional dark overlay for contrast
            Container(color: Colors.black26),

            // 3) Info panel at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Colors.black26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$qty개',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4) 선택된 경우 체크 배지 표시
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white70,
                  child: Icon(Icons.check, size: 20, color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
