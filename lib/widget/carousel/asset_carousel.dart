import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AssetCarousel extends StatefulWidget {
  /// 이미지 + 텍스트 묶음 리스트
  /// - network == true  -> item['imageUrl'] 사용
  /// - network == false -> item['assetPath'] 사용
  final List<Map<String, dynamic>> items;

  /// 캐러셀 높이
  final double height;

  /// 자동 재생 여부
  final bool autoPlay;

  /// 네트워크 이미지 사용 여부
  final bool network;

  const AssetCarousel({
    super.key,
    required this.items,
    this.height = 380,
    this.autoPlay = true,
    this.network = false,
  });

  @override
  _AssetCarouselState createState() => _AssetCarouselState();
}

class _AssetCarouselState extends State<AssetCarousel> {
  int _currentIndex = 0;

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> item) {
    if (widget.network) {
      final url = item['imageUrl'] as String?;
      if (url == null || url.isEmpty) return _errorPlaceholder();

      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) => _errorPlaceholder(),
      );
    } else {
      final path = item['assetPath'] as String?;
      if (path == null || path.isEmpty) return _errorPlaceholder();

      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stack) => _errorPlaceholder(),
      );
    }
  }

  bool _hasText(String? s) => (s?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CarouselSlider(
          items: widget.items.map((item) {
            final title = item['title'] as String?;
            final subtitle = item['subtitle'] as String?;
            return Stack(
              fit: StackFit.expand,
              children: [
                // 배경 이미지 (asset / network 분기)
                _buildImage(item),

                // overlay: title이나 subtitle이 있을 때만 표시
                if (_hasText(title) || _hasText(subtitle))
                  Positioned(
                    left: 16,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hasText(title))
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black45),
                              ],
                            ),
                          ),
                        if (_hasText(subtitle)) const SizedBox(height: 4),
                        if (_hasText(subtitle))
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black45),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          }).toList(),
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 1,
            autoPlay: widget.autoPlay,
            onPageChanged: (idx, _) => setState(() => _currentIndex = idx),
          ),
        ),

        // ▶ 우측 하단 인덱스
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentIndex + 1}/${widget.items.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
