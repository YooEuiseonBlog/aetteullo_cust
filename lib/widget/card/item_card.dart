import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ItemCard extends StatefulWidget {
  final String? imgUrl;
  final String title;
  final double price;
  final double originalPrice;
  final double rate;
  final String promoYn;
  final String? mnfct;
  final ValueChanged<int>? onQuantitySelected;
  final VoidCallback? onClick;
  final VoidCallback? onImageTap; // 이미지 클릭 콜백 추가

  const ItemCard({
    super.key,
    required this.imgUrl,
    required this.title,
    required this.price,
    this.mnfct,
    this.onClick,
    this.onQuantitySelected,
    this.onImageTap,
    required this.originalPrice,
    required this.promoYn,
    required this.rate, // 생성자에 포함
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _selecting = false; // 수량 선택 모드 여부
  int _quantity = 1; // 선택된 수량
  final FocusNode _focusNode = FocusNode(); // 카드 포커스 관리를 위한 FocusNode

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _selecting) {
        setState(() => _selecting = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _openSelector() {
    setState(() {
      _selecting = true;
      _quantity = 1;
    });
    _focusNode.requestFocus();
  }

  void _confirm() {
    widget.onQuantitySelected?.call(_quantity);
    setState(() => _selecting = false);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = formatCurrency(widget.price);
    final formattedOriginalPrice = formatCurrency(widget.originalPrice);

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!_selecting) {
            _focusNode.requestFocus();
          }
        },
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: GestureDetector(
                          onTap: widget.onImageTap, // 이미지 클릭 시 호출
                          child: CachedNetworkImage(
                            imageUrl: widget.imgUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (ctx, url, err) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mnfct == null || widget.mnfct!.isEmpty
                                ? '미상'
                                : widget.mnfct!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (widget.promoYn == 'Y') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '$formattedOriginalPrice원',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${(widget.rate).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$formattedPrice원',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ] else
                            Text(
                              '$formattedPrice원',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // + 버튼: 선택 모드가 아닐 때만 표시
                if (!_selecting)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton.filled(
                      onPressed: _openSelector,
                      icon: const Icon(Icons.add),
                      iconSize: 25,
                      tooltip: '아이템 추가',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        minimumSize: const Size(32, 32),
                        padding: const EdgeInsets.all(4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                if (_selecting)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 수량 선택 Row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                  icon: const Icon(Icons.remove),
                                  color: Colors.white,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '$_quantity',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _quantity++),
                                  icon: const Icon(Icons.add),
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 확인 버튼
                            TextButton(
                              onPressed: _confirm,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('담기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
