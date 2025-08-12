import 'dart:async';

import 'package:aetteullo_cust/function/etc.dart';
import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/observer/route_observer.dart';
import 'package:aetteullo_cust/screen/basket/basket_screen.dart';
import 'package:aetteullo_cust/screen/item/item_screen.dart';
import 'package:aetteullo_cust/service/basket_service.dart';
import 'package:aetteullo_cust/service/category_service.dart';
import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/item_card_v2.dart';
import 'package:aetteullo_cust/widget/card/item_set_card.dart';
import 'package:aetteullo_cust/widget/chip/mobile_chip.dart';
import 'package:aetteullo_cust/widget/filterbar/filter_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:aetteullo_cust/widget/nodata/no_data.dart';
import 'package:aetteullo_cust/widget/sheet/filter_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class OrderListScreen extends StatefulWidget {
  final String? title;
  final String? ctgry;
  static String routeName = '/order';

  const OrderListScreen({super.key, this.title, this.ctgry});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with RouteAware {
  final CategoryService _categoryService = CategoryService();
  final BasketService _basketService = BasketService();
  final ItemService _itemService = ItemService();

  final List<GlobalKey<ItemCardV2State>> _cardKeys = [];
  List<Map<String, dynamic>> _items = [];
  Map<String, List<Map<String, dynamic>>> _categories = {};

  // ─── 추가: 검색(로딩) 상태 플래그
  bool _isLoading = false;

  // ① 선택된 카테고리와 가격 범위를 상태로 추가
  final List<Map<String, dynamic>> _selectedCategories = [];
  // ② 선택된 가격 범위: 처음엔 null
  RangeValues? _selectedRange;

  final ScrollController _scrollController = ScrollController();
  bool _isScrollEnd = false;

  List<Map<String, dynamic>> get _selectedItems =>
      _items.where((i) => (i['qty'] as double? ?? 0.0) > 0).toList();

  /// (2) 전체 선택 개수
  double get _totQty =>
      _selectedItems.fold(0.0, (sum, i) => sum += i['qty'] as double? ?? 0.0);

  /// (3) 전체 금액 합계
  double get _totAmnt => _selectedItems.fold(
    0.0,
    (amnt, i) =>
        amnt += (i['price'] as double? ?? 0.0) * (i['qty'] as double? ?? 0.0),
  );

  List<Map<String, dynamic>> _itemSetList = [];

  @override
  void initState() {
    super.initState();
    _loadItems(fixCtgry: widget.ctgry);
    _getCategory();
    if (widget.ctgry == null ||
        (widget.ctgry != null && widget.ctgry!.isEmpty) ||
        widget.ctgry == '전체') {
      _getItemSetList();
    }

    // 변경: 스크롤 리스너 등록
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // 뒤에서 돌아올 때 한 번에 리셋
    for (final key in _cardKeys) {
      ItemCardV2.resetByKey(key);
    }

    setState(() {
      _selectedItems.clear();
    });

    _applyFilters();
    if (widget.ctgry == '전체' || widget.ctgry == null) {
      _getItemSetList();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _onScroll() {
    final atEnd =
        _scrollController.position.atEdge &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent;

    if (atEnd && !_isScrollEnd) {
      setState(() => _isScrollEnd = true);
    } else if (!atEnd && _isScrollEnd) {
      setState(() => _isScrollEnd = false);
    }
  }

  void _toggleLikeState({required Map<String, dynamic> item}) async {
    final itemId = item['itemId'] as int;
    final itemNm = item['itemNm'] as String? ?? '';
    final like = item['like'] as String? ?? 'N';
    try {
      await _itemService.toggleLikeState(itemId: itemId);
      if (mounted) {
        final message = getLikeMessage(itemNm, like);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e, stackTrace) {
      debugPrint('$e: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('관심품목 작업 중 에러가 발생하였습니다.')));
      }
    }
  }

  Future<void> _addBasketItems() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _basketService.saveBasketItems(
        items: _selectedItems,
        context: context,
      );
    } catch (e) {
      debugPrint('error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('장바구니 추가를 실패하였습니다.')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 필터 기준을 받아 API 호출
  Future<void> _loadItems({
    String? itemNm,
    String? fixCtgry,
    List<String>? mainCtgries,
    List<String>? midCtgries,
    List<String>? subCtgries,
    List<String>? origins,
    List<String>? mnfctComs,
    List<int>? unitIds,
    double? minPrice,
    double? maxPrice,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resp = await _itemService.searchItemList(
        itemNm: itemNm,
        fixCtgry: fixCtgry,
        mainCtgries: mainCtgries,
        midCtgries: midCtgries,
        subCtgries: subCtgries,
        origins: origins,
        mnfcts: mnfctComs,
        unitIds: unitIds,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      setState(() {
        _items = resp.map((i) => {...i, 'qty': 0.0}).toList();
        _cardKeys
          ..clear()
          ..addAll(
            List.generate(_items.length, (_) => GlobalKey<ItemCardV2State>()),
          );
      });
    } catch (e, stackTrace) {
      debugPrint('error occurs: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('아이템을 불러오는 중에 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _selectedItems.clear();
      });
    }
  }

  Future<void> _getItemSetList({String? itemNm, String? setNm}) async {
    try {
      _itemSetList = await _itemService.getItemSetList(
        itemNm: itemNm,
        setNm: setNm,
      );
    } catch (e) {
      _itemSetList = [];
      debugPrint('_getItemSetList error : $e');
    } finally {
      setState(() {});
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        // 이미 선택된 상태를 초기값으로 넘겨주면 Sheet 열 때도 반영됩니다.
        initialCategories: _selectedCategories,
        initialRange: _selectedRange ?? const RangeValues(0, 100000),
        mainCtgry: _categories['main'],
        midCtgry: _categories['mid'],
        subCtgry: _categories['sub'],
        onApply: (cats, range) {
          // 2) 상태 업데이트
          setState(() {
            _selectedCategories
              ..clear()
              ..addAll(cats);
            _selectedRange = range;
          });
          // 3) 필터 재적용 API 호출
          _applyFilters();
        },
      ),
    );
  }

  // 1) _showItemSetSheet 내부: items에 'qty' 초기화
  void _showItemSetSheet(Map<String, dynamic> itemSet) {
    final items = itemSet['items'] as List<Map<String, dynamic>>;
    // 각 아이템 맵에 'qty' 키를 0으로 초기화
    for (var item in items) {
      item['qty'] = 0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      itemSet['setNm'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        final int qty = item['qty'] as int; // 기존 Map에서 직접 읽기

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: (item['image1'] as String).isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item['image1'] as String,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : const Icon(Icons.image_not_supported),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['itemNm'] as String? ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${formatCurrency(item['price'])}원',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 수량 조절 버튼
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: qty > 0
                                        ? () {
                                            setModalState(() {
                                              item['qty'] =
                                                  qty - 1; // 직접 Map에 저장
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    qty.toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      setModalState(() {
                                        item['qty'] = qty + 1; // 직접 Map에 저장
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: items.every((i) => (i['qty'] as int) == 0)
                          ? null
                          : () async {
                              final itemsToAdd = items
                                  .where((i) => (i['qty'] as int) > 0)
                                  .map(
                                    (i) => <String, dynamic>{
                                      'itemId': i['itemId'],
                                      'qty': i['qty'],
                                    },
                                  )
                                  .toList();
                              await _basketService.saveBasketItems(
                                items: itemsToAdd,
                                context: context,
                              );
                              setState(() {
                                Navigator.pop(context);
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('장바구니에 담기'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 현재 선택된 카테고리·가격을 API 호출 인자 형태로 만들어 다시 로드
  void _applyFilters() {
    // 레벨별 이름 리스트 추출
    final mainList = _selectedCategories
        .where((e) => e['level'] == 'main')
        .map((e) => e['name'] as String)
        .toList();
    final midList = _selectedCategories
        .where((e) => e['level'] == 'mid')
        .map((e) => e['name'] as String)
        .toList();
    final subList = _selectedCategories
        .where((e) => e['level'] == 'sub')
        .map((e) => e['name'] as String)
        .toList();

    _loadItems(
      fixCtgry: widget.ctgry,
      mainCtgries: mainList.isNotEmpty ? mainList : null,
      midCtgries: midList.isNotEmpty ? midList : null,
      subCtgries: subList.isNotEmpty ? subList : null,
      minPrice: _selectedRange?.start,
      maxPrice: _selectedRange?.end,
    );
  }

  Future<void> _getCategory() async {
    try {
      final fetchedCtgry = await _categoryService.fetchCategory();
      setState(() {
        _categories = fetchedCtgry;
      });
    } on Exception catch (e) {
      debugPrint("_getCategory error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카테고리 불러오기 중에 오류가 발생하였습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: MobileAppBar(
        title: Text(
          widget.title ?? '전체',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showNotification: false,
      ),
      // Scaffold 에서 bottomSheet 부분만 발췌
      bottomSheet: _buildBottomSheet(),
      bottomNavigationBar: const MobileBottomNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① 가로로 스크롤되는 세트 리스트 추가
              if (_itemSetList.isNotEmpty) ...[
                _buildHorizontalItemSetList(),
                const SizedBox(height: 12),
              ],
              // ─── 필터 옵션 바 ─────────────────────────────
              if (widget.ctgry == null || widget.ctgry == '전체')
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: FilterBar(
                    chips: [
                      // 카테고리 Chip (오른쪽만 8px 간격)
                      ..._selectedCategories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: MobileChip(
                            label: cat['name'],
                            onDeleted: () {
                              setState(() => _selectedCategories.remove(cat));
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                      // 가격대 Chip
                      if (_selectedRange != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: MobileChip(
                            label:
                                '${_selectedRange!.start.toInt()}원 ~ ${_selectedRange!.end.toInt()}원',
                            onDeleted: () {
                              setState(() => _selectedRange = null);
                              _applyFilters();
                            },
                          ),
                        ),
                    ],
                    onFilterTap: _showFilterSheet,
                  ),
                ),
              // ─── 상품 리스트 ─────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? const NoData()
                    : GridView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: (_totQty > 0 && _isScrollEnd) ? 80 : 0,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2열
                              crossAxisSpacing: 8, // 열 간격
                              mainAxisSpacing: 8, // 행 간격
                              childAspectRatio: 0.65, // 너비/높이 비율
                            ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final key = _cardKeys[index];
                          return ItemCardV2(
                            key: key,
                            item: item,
                            onLikeChanged: (newLike) {
                              setState(() {
                                item['like'] = newLike;
                                _toggleLikeState(item: item);
                              });
                            },
                            onQuantityChanged: (newQty) {
                              setState(() {
                                item['qty'] = newQty.toDouble();
                              });
                            },
                            onClick: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ItemScreen(item: item),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
      height: _totQty > 0 ? 80 : 0,
      // child 가 null 이면 아무것도 렌더링되지 않습니다.
      child: _totQty > 0
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('장바구니 담기', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      if (_selectedItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('선택된 아이템이 없습니다.')),
                        );
                        return;
                      }
                      await _addBasketItems();

                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BasketScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green, // 버튼 색상과 통일
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1) 흰 원 안에 수량
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${_totQty.toInt()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // 2) 포맷된 가격
                          Text(
                            '${formatCurrency(_totAmnt)}원',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  /// 2) “옆으로(가로로) 스크롤되는 리스트” 위젯
  Widget _buildHorizontalItemSetList() {
    // 데이터가 비어있으면 빈 공간만 반환
    if (_itemSetList.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100, // 카드 높이를 적절히 조절하세요
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // 가로 스크롤
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _itemSetList.length,
        itemBuilder: (context, index) {
          final itemSet = _itemSetList[index];
          final String setName = itemSet['setNm'] as String? ?? '세트명 없음';
          final String setImageUrl =
              (itemSet['items'] as List<Map<String, dynamic>>).first['image1']
                  as String? ??
              '';

          return ItemSetCard(
            name: setName,
            imgUrl: setImageUrl,
            onTap: () {
              _showItemSetSheet(itemSet);
            },
          );
        },
      ),
    );
  }
}
