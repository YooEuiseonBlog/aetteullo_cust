import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ItemCardV2 extends StatefulWidget {
  final Map<String, dynamic> item;
  final ValueChanged<String> onLikeChanged;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onClick;

  const ItemCardV2({
    super.key,
    required this.item,
    required this.onLikeChanged,
    this.onClick,
    this.onQuantityChanged,
  });

  /// GlobalKey로 부터 해당 카드의 수량을 0으로 리셋
  static void resetByKey(GlobalKey<ItemCardV2State> key) {
    key.currentState?.resetQuantity();
  }

  @override
  State<ItemCardV2> createState() => ItemCardV2State();
}

class ItemCardV2State extends State<ItemCardV2> {
  late final ValueNotifier<int> _qtyNotifier;
  late final TextEditingController _qtyCtrl;
  late final FocusNode _qtyFocusNode;
  bool _showQtyController = false;

  @override
  void initState() {
    super.initState();
    _qtyNotifier = ValueNotifier<int>(0);
    _qtyCtrl = TextEditingController(text: '0');
    _qtyFocusNode = FocusNode()..addListener(_onQtyFocusChange);
    _qtyNotifier.addListener(_onQtyChanged);
  }

  /// 외부(부모)에서 호출할 수 있는 reset 메서드
  void resetQuantity() {
    _qtyNotifier.value = 0;
  }

  @override
  void dispose() {
    _qtyNotifier.removeListener(_onQtyChanged);
    _qtyNotifier.dispose();
    _qtyFocusNode.removeListener(_onQtyFocusChange);
    _qtyFocusNode.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _onQtyChanged() {
    final q = _qtyNotifier.value;
    _qtyCtrl.text = q.toString();
    setState(() {
      _showQtyController = q > 0;
    });
    widget.onQuantityChanged?.call(q);
  }

  void _onQtyFocusChange() {
    if (!_qtyFocusNode.hasFocus) {
      // 포커스 풀릴 때, 마지막 텍스트를 파싱해 notifier에 반영
      final parsed = int.tryParse(_qtyCtrl.text) ?? _qtyNotifier.value;
      _qtyNotifier.value = parsed;
    }
  }

  // + 버튼
  void _increment() {
    _qtyNotifier.value++;
  }

  // – 버튼
  void _decrement() {
    if (_qtyNotifier.value > 0) {
      _qtyNotifier.value--;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = formatCurrency(widget.item['price']);
    final formattedOriginalPrice = formatCurrency(widget.item['originalPrice']);
    final like = widget.item['like'] as String? ?? 'N';

    return Card(
      color: Colors.white,
      elevation: 1.3,
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

                // 2) 좋아요 버튼
                Positioned(
                  left: 8,
                  top: 8,
                  child: InkWell(
                    onTap: widget.onClick,
                    child: const Icon(
                      size: 25,
                      Icons.info,
                      color: Colors.green,
                    ),
                  ),
                ),

                // 2) 좋아요 버튼
                Positioned(
                  right: 8,
                  top: 8,
                  child: _LikeButton(
                    like: like,
                    onChanged: widget.onLikeChanged,
                  ),
                ),

                // 3) + 버튼 (컨트롤러 꺼져 있을 때만)
                if (!_showQtyController)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: _increment,
                      icon: const Icon(Icons.add, color: Colors.white),
                      tooltip: 'Add',
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.green),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.all(4),
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                // 4) 수량 컨트롤러 (켜져 있을 때만)
                if (_showQtyController)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        //① 고정 너비를 줄 경우
                        // width: 120,

                        //② 최소 너비를 줄 경우 (내용물보다 작으면 120, 크면 내용물만큼)
                        constraints: const BoxConstraints(minWidth: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              visualDensity: VisualDensity.compact,
                              onPressed: _decrement,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _qtyCtrl,
                                focusNode: _qtyFocusNode,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              visualDensity: VisualDensity.compact,
                              onPressed: _increment,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 상품 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((widget.item['mnfct'] as String?)?.isNotEmpty ?? false)
                  Text(
                    widget.item['mnfct'],
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                Text(
                  '${widget.item['itemNm'] ?? ''}(${widget.item['unitNm']})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.item['promoYn'] == 'Y') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$formattedOriginalPrice원',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        '${(widget.item['rate'] as double).toInt()}%',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final String? like;
  final ValueChanged<String>? onChanged;
  const _LikeButton({this.like = 'N', this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // onChanged 콜백이 있을 때만 실행
        if (onChanged != null) {
          // 현재 값의 반대값을 전달
          final newValue = like == 'Y' ? 'N' : 'Y';
          onChanged!.call(newValue);
        }
      },
      child: like == 'Y'
          ? const Icon(Icons.favorite, size: 25, color: Colors.red)
          : const Icon(Icons.favorite_border, size: 25, color: Colors.white),
    );
  }
}
