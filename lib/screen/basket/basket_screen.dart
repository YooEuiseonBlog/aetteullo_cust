import 'dart:async';

import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/screen/item/item_screen.dart';
import 'package:aetteullo_cust/screen/order/order_form_screen.dart';
import 'package:aetteullo_cust/service/basket_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/basket_card.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:aetteullo_cust/widget/nodata/no_basket.dart';
import 'package:flutter/material.dart';

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  bool _isLoading = false;

  final GlobalKey _bottomSheetKey = GlobalKey();
  double _bottomSheetHeight = 0;

  final BasketService _basketService = BasketService();
  List<Map<String, dynamic>> _bkItems = []; // 빈 리스트로 초기화

  bool get _allSelected =>
      _bkItems.isNotEmpty && _bkItems.every((i) => i['selected'] as bool);

  List<Map<String, dynamic>> get _selectedBkItems =>
      _bkItems.where((bk) => bk['selected'] as bool).toList();

  @override
  void initState() {
    super.initState();
    loadBkItems();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadBkItems() async {
    try {
      _isLoading = true;
      final bkItems = await _basketService.selectBasketItemList();

      setState(() {
        _bkItems = bkItems.map((i) => {...i, 'selected': false}).toList();
      });
    } catch (error) {
      debugPrint('error iccurs: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장바구니 정보를 가져오는 도중에 에러가 발생하였습니다.')),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  /// 전체 선택/해제 토글
  void _toggleSelectAll(bool? checked) {
    final newVal = checked ?? false;
    setState(() {
      for (var item in _bkItems) {
        item['selected'] = newVal;
      }
    });
  }

  Future<void> onTapClose({required Map<String, dynamic> item}) async {
    await _basketService.deleteBasketItems(items: [item], context: context);
    setState(() {
      _bkItems.removeWhere(
        (i) =>
            i['itemId'] == item['itemId'] &&
            i['industCd'] == item['industCd'] &&
            i['partnerCd'] == item['partnerCd'],
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item['itemNm']}을(를) 삭제하였습니다.')));
    });
  }

  Future<void> _deleteBkItems() async {
    // ① 삭제할 항목을 getter 로 꺼내오기
    final items = _selectedBkItems;
    if (items.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1) 서버에 삭제 요청 (getter 반환 리스트 사용)
      await _basketService.deleteBasketItems(items: items, context: context);

      // 2) 로컬 목록 갱신 및 선택 초기화
      setState(() {
        // 'selected' == true 인 애들 모두 제거
        _bkItems.removeWhere((i) => i['selected'] as bool);

        // 남은 항목들 모두 체크 해제
        for (var e in _bkItems) {
          e['selected'] = false;
        }
      });

      // 3) 사용자에게 성공 알림
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('선택한 품목을 삭제하였습니다.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 1) 삭제 전 확인 다이얼로그
  Future<bool> _showDeleteConfirmDialog(int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('$count개 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  /// 2) 확인 후 삭제를 실행하는 래퍼
  Future<void> _confirmAndDelete() async {
    final ok = await _showDeleteConfirmDialog(_selectedBkItems.length);
    if (!ok) return;
    await _deleteBkItems();
  }

  // 1) 시그니처를 items만 받도록 변경
  Widget _buildBottomSheet() {
    // 2) 내부에서 count와 price 계산
    final count = _selectedBkItems.length;
    final amnt = _selectedBkItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item['price'] as double? ?? 0.0) *
              (item['bkQty'] as double? ?? 0.0)),
    );

    return Container(
      key: _bottomSheetKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '총 구매금액',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '총 ${formatCurrency(amnt)}원',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // 3) 구매하기 누르면 OrderFormScreen으로 items 넘기기
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderFormScreen(items: _selectedBkItems),
                  ),
                );
              },
              child: Text(
                '$count건 구매하기', // items.length 로 count 사용
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBkItem({required int itemId, required double qty}) async {
    try {
      await _basketService.updateBasketItems(
        items: [
          {'itemId': itemId, 'qty': qty},
        ],
        context: context,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('수량을 변경하였습니다.')));
      }
    } catch (e) {
      debugPrint('error iccurs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수량 변경 작업 중 에러가 발생하였습니다.')),
        );
      }
    }
  }

  void showOptionSheet({required Map<String, dynamic> item}) {
    final double originalQty = item['bkQty'] ?? 0.0;
    double selectedQty = originalQty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이 조절 가능
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return Padding(
          // 키보드 올라올 때도 같이 올라오도록
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ), // 상단에만 borderRadius 적용
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) 상단 바
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '옵션/수량 변경',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['itemNm'],
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 4) 수량 조절
                      // ── 커스텀 수량 컨트롤러 시작 ──
                      Row(
                        children: [
                          const Text('수량'),
                          const SizedBox(width: 20),
                          QuantityController(
                            initialValue: selectedQty.toInt(),
                            min: 1,
                            max: 999,
                            onChanged: (newQty) {
                              setModalState(
                                () => selectedQty = newQty.toDouble(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 5) 저장 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedQty != originalQty
                              ? () async {
                                  setState(() {
                                    item['bkQty'] = selectedQty;
                                  });

                                  _updateBkItem(
                                    itemId: item['itemId'],
                                    qty: item['bkQty'],
                                  );

                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedQty != originalQty
                                ? Colors.green
                                : Colors.grey,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '변경하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 기기 안전 영역
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    // 측정된 bottomSheet 높이가 있으면 그만큼 + safeAreaBottom, 없으면 safeAreaBottom
    final listBottomPadding =
        (_bottomSheetHeight > 0 && _selectedBkItems.isNotEmpty)
        ? _bottomSheetHeight + safeAreaBottom
        : safeAreaBottom;

    // ▼ 이 부분만 바꿔줍니다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // ← 여기를 꼭 추가!
      if (_selectedBkItems.isNotEmpty) {
        final ctx = _bottomSheetKey.currentContext;
        final newHeight = ctx?.size?.height ?? 0;
        if (newHeight > 0 && newHeight != _bottomSheetHeight) {
          setState(() => _bottomSheetHeight = newHeight);
        }
      } else if (_bottomSheetHeight != 0) {
        setState(() => _bottomSheetHeight = 0);
      }
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '장바구니',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showBasket: false,
        showNotification: true,
        showSearch: false,
      ),
      bottomSheet: _selectedBkItems.isNotEmpty ? _buildBottomSheet() : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1) 전체 선택 / 전체 삭제 위젯
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _allSelected,
                  activeColor: Colors.green,
                  onChanged: _toggleSelectAll,
                ),
                // 체크박스 + 텍스트 전체 영역 터치 가능
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _toggleSelectAll(!_allSelected),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      child: const Text('전체 선택'),
                    ),
                    // 세로 구분선
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey[300],
                      padding: EdgeInsets.zero,
                    ),
                    // 전체 삭제 버튼
                    TextButton(
                      onPressed: _isLoading || _selectedBkItems.isEmpty
                          ? null
                          : () => _confirmAndDelete(),
                      style: TextButton.styleFrom(
                        foregroundColor: _selectedBkItems.isNotEmpty
                            ? Colors.red
                            : Colors.black26,
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      child: const Text('선택 삭제'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          // ── 2) 카드 리스트
          Expanded(
            child: Builder(
              builder: (_) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_bkItems.isEmpty) {
                  return const NoBasket();
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    10,
                    0,
                    10,
                    listBottomPadding + 10,
                  ),
                  itemCount: _bkItems.length,
                  itemBuilder: (ctx, idx) {
                    final bkItem = _bkItems[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: BasketCard(
                        isChecked: bkItem['selected'],
                        itemNm: bkItem['itemNm'],
                        price: bkItem['price'] ?? 0.0,
                        qty: bkItem['bkQty'] as double? ?? 0.0,
                        image: bkItem['image1'],
                        mnfct: bkItem['mnfct'],
                        promoYn: bkItem['promoYn'],
                        originalPrice: bkItem['originalPrice'],
                        rate: bkItem['rate'],
                        onEditOptionsPressed: () {
                          showOptionSheet(item: bkItem);
                        },
                        onCheckoutPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderFormScreen(items: [bkItem]),
                            ),
                          );
                        },
                        onCheckedChanged: (bool? selected) {
                          setState(() {
                            bkItem['selected'] = selected!;
                          });
                        },
                        onClosePressed: () => onTapClose(item: bkItem),
                        onImageTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemScreen(item: bkItem),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.5),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}

/// 재사용 가능한 커스텀 수량 컨트롤러 위젯
class QuantityController extends StatefulWidget {
  /// 초기값
  final int initialValue;

  /// 최소값
  final int min;

  /// 최대값
  final int max;

  /// 값이 변경될 때 호출될 콜백
  final ValueChanged<int>? onChanged;

  const QuantityController({
    super.key,
    required this.initialValue,
    this.min = 1,
    this.max = 999,
    this.onChanged,
  });

  @override
  State<QuantityController> createState() => _QuantityControllerState();
}

class _QuantityControllerState extends State<QuantityController> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _decrement() {
    if (_value > widget.min) {
      setState(() => _value--);
      widget.onChanged?.call(_value);
    }
  }

  void _increment() {
    if (_value < widget.max) {
      setState(() => _value++);
      widget.onChanged?.call(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _value > widget.min ? _decrement : null,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove,
                size: 20,
                color: _value > widget.min ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              '$_value',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          InkWell(
            onTap: _increment,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 20, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
