import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ItemSetCard extends StatelessWidget {
  final String name;
  final String imgUrl;
  final VoidCallback? onTap;

  const ItemSetCard({
    super.key,
    required this.name,
    required this.imgUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 이미지
            imgUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 40),
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.collections_bookmark,
                      size: 40,
                      color: Colors.white70,
                    ),
                  ),

            // 이미지 위에 반투명 오버레이 + 텍스트
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
