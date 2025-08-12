import 'package:aetteullo_cust/screen/item/item_screen.dart';
import 'package:aetteullo_cust/service/basket_service.dart';
import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/card/item_card_v4.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LikeTab extends StatefulWidget {
  const LikeTab({super.key});

  @override
  State<LikeTab> createState() => _LikeTabState();
}

class _LikeTabState extends State<LikeTab> {
  final BasketService _basketService = BasketService();
  final ItemService _itemService = ItemService();

  List<Map<String, dynamic>> _likeItems = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadLikeItems();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLikeItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _itemService.searchItemList();
      setState(() {
        _likeItems = items
            .where((i) => i['like'] == 'Y')
            .map((i) => {...i, 'qty': 0.0})
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심 품목을 불러오는 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLikeState({required Map<String, dynamic> item}) async {
    final itemId = item['itemId'] as int;
    try {
      await _itemService.toggleLikeState(itemId: itemId);
      _loadLikeItems();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> _addBasketItem({required Map<String, dynamic> item}) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _basketService.saveBasketItems(items: [item], context: context);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('장바구니에 추가되었습니다.')));
      }
    } catch (e, stackTrace) {
      debugPrint('[_addBasketItem] Error: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('장바구니 추가 중 오류가 발생했습니다.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showQtyDialog({required Map<String, dynamic> item}) async {
    final qtyCtrl = TextEditingController(text: '1');
    int currentQty = 1;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('수량'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // – 버튼
                  IconButton(
                    iconSize: 35,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: currentQty > 1
                        ? () {
                            setState(() {
                              currentQty--;
                              qtyCtrl.text = currentQty.toString();
                            });
                          }
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    width: 60,
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        final parsed = int.tryParse(v) ?? currentQty;
                        setState(() {
                          currentQty = parsed < 1 ? 1 : parsed;
                        });
                      },
                    ),
                  ),

                  // + 버튼
                  IconButton(
                    iconSize: 35,
                    color: Colors.green,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        currentQty++;
                        qtyCtrl.text = currentQty.toString();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('담기'),
            ),
          ],
        );
      },
    );

    if (result != null && result) {
      item['qty'] = currentQty.toDouble();
      await _addBasketItem(item: item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _likeItems.isEmpty
              ? const Center(child: Text('관심 품목이 없습니다.'))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2열
                    mainAxisSpacing: 8, // 행 간격
                    crossAxisSpacing: 8, // 열 간격
                    childAspectRatio: 0.65, // 너비/높이 비율
                  ),
                  itemCount: _likeItems.length,
                  itemBuilder: (context, index) {
                    final item = _likeItems[index];
                    return ItemCardV4(
                      item: item,
                      onDelete: () {
                        _toggleLikeState(item: item);
                      },
                      onClickBtn: () {
                        _showQtyDialog(item: item);
                      },
                      onClick: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemScreen(item: item),
                          ),
                        );
                        _loadLikeItems();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
