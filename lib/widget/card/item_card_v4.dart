import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ItemCardV4 extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onDelete;
  final VoidCallback? onClick;
  final VoidCallback? onClickBtn;

  const ItemCardV4({
    super.key,
    required this.item,
    this.onDelete,
    this.onClick,
    this.onClickBtn,
  });

  @override
  State<ItemCardV4> createState() => _ItemCardV4State();
}

class _ItemCardV4State extends State<ItemCardV4> {
  @override
  Widget build(BuildContext context) {
    final formattedPrice = formatCurrency(widget.item['price']);
    final formattedOriginalPrice = formatCurrency(
      widget.item['originalPrice'] ?? 0.0,
    );
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 + 좋아요 + 수량 컨트롤러
          Expanded(
            child: Stack(
              children: [
                // 1) 배경 이미지
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: widget.item['image1'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),

                // 2) 삭제 버튼
                if (widget.onDelete != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.close,
                        size: 25,
                        color: Colors.black.withOpacity(0.4),
                      ),
                      onPressed: widget.onDelete,
                    ),
                  ),

                Positioned(
                  left: 0,
                  top: 0,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.info,
                      size: 25,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    onPressed: widget.onClick,
                  ),
                ),
              ],
            ),
          ),
          // 상품 정보
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            width: double.maxFinite,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((widget.item['mnfctCom'] as String?)?.isNotEmpty ??
                        false)
                      Text(
                        widget.item['mnfctCom'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    Text(
                      widget.item['itemNm'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (((widget.item['promoYn'] as String? ?? 'N')) ==
                        'Y') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$formattedOriginalPrice원',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            '${(widget.item['rate'] as double? ?? 0.0).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$formattedPrice원',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '$formattedPrice원',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: widget.onClickBtn,
                              style: ButtonStyle(
                                // 1) 내부 여백 제거
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                ),
                                // 2) 최소 크기 제거
                                minimumSize: WidgetStateProperty.all(Size.zero),
                                // 3) 터치 타깃도 위젯 크기에 딱 맞춤
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: WidgetStateProperty.all(
                                  const TextStyle(fontSize: 14),
                                ),
                                foregroundColor: WidgetStateProperty.all(
                                  Colors.white,
                                ),
                                backgroundColor: WidgetStateProperty.all(
                                  Colors.green,
                                ),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              child: const Text('담기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityController extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// 내용물보다 작으면 이 너비, 크면 내용물만큼
  final double minWidth;

  /// 부모가 지정해 주는 높이 (지정하지 않으면 내용물 높이)
  final double? height;

  const QuantityController({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.minWidth = 120,
    this.height,
  });

  Widget _actionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 높이를 지정하거나, 지정 없으면 내부 콘텐츠 크기에 맞춤
      height: height,
      constraints: BoxConstraints(
        minWidth: minWidth,
        // 만약 height도 최소 높이로 보장하고 싶으면 아래 주석 해제
        // minHeight: height ?? 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionButton(Icons.remove, onDecrement),
          Text(
            '$quantity',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
          _actionButton(Icons.add, onIncrement),
        ],
      ),
    );
  }
}
