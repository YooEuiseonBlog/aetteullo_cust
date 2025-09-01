import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/observer/route_observer.dart';
import 'package:aetteullo_cust/screen/basket/basket_screen.dart';
import 'package:aetteullo_cust/screen/search/search_screen.dart';
import 'package:aetteullo_cust/service/basket_service.dart';
import 'package:aetteullo_cust/service/common_service.dart';
import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/item_card_v2.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:aetteullo_cust/widget/nodata/no_data.dart';
import 'package:flutter/material.dart';

class SearchRstScreen extends StatefulWidget {
  final String? searchKeyword;

  const SearchRstScreen({super.key, this.searchKeyword});

  @override
  State<SearchRstScreen> createState() => _SearchRstScreenState();
}

class _SearchRstScreenState extends State<SearchRstScreen> with RouteAware {
  final CommonService _commonService = CommonService();
  final BasketService _basketService = BasketService();
  final ItemService _itemService = ItemService();

  List<Map<String, dynamic>> _items = [];
  final List<GlobalKey<ItemCardV2State>> _cardKeys = [];

  /// 검색 중 플래그
  bool _isLaoding = false;

  /// 스크롤 컨트롤러 (끝 도달 여부 감지용)
  final ScrollController _scrollController = ScrollController();
  bool _isScrollEnd = false;

  /// 각 아이템별 수량 (itemId → qty)
  List<Map<String, dynamic>> get _selectedItems =>
      _items.where((i) => (i['qty'] as double? ?? 0.0) > 0).toList();

  /// 전체 선택 개수
  double get _totQty =>
      _selectedItems.fold(0.0, (sum, i) => sum += i['qty'] as double? ?? 0.0);

  /// 전체 금액 합계
  double get _totAmnt => _selectedItems.fold(
    0.0,
    (amnt, i) =>
        amnt += (i['qty'] as double? ?? 0.0) * (i['price'] as double? ?? 0.0),
  );

  @override
  void initState() {
    super.initState();
    // ①: searchKeyword를 itemNm 필터로 적용하여 초기 로드
    _loadItems(itemNm: widget.searchKeyword);

    // 스크롤 리스너 등록 (끝 도달 감지)
    _scrollController.addListener(() {
      final atEnd =
          _scrollController.position.atEdge &&
          _scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent;
      if (atEnd && !_isScrollEnd) {
        setState(() => _isScrollEnd = true);
      } else if (!atEnd && _isScrollEnd) {
        setState(() => _isScrollEnd = false);
      }
    });
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
    // 1. 실제 데이터의 qty를 0으로 초기화
    for (var item in _items) {
      item['qty'] = 0.0;
    }

    // 2. 카드 UI도 리셋
    for (final key in _cardKeys) {
      ItemCardV2.resetByKey(key);
    }

    setState(() {}); // UI 업데이트
  }

  @override
  void dispose() {
    // RouteAware 구독 해제
    routeObserver.unsubscribe(this);

    // 변경: 컨트롤러 해제
    _scrollController.dispose();
    super.dispose();
  }

  /// 필터 기준을 받아 API 호출
  ///
  /// 여기서 itemNm에 검색어를 전달
  Future<void> _loadItems({
    String? itemNm,
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
      _isLaoding = true;
    });

    try {
      final responseItems = await _itemService.searchItemList(
        itemNm: itemNm,
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
        _items = responseItems.map((i) => {...i, 'qty': 0.0}).toList();
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
        _isLaoding = false;
      });
    }
  }

  /// 장바구니에 선택된 아이템들 한꺼번에 추가
  Future<void> _addBasketItems() async {
    if (_isLaoding) return;
    try {
      _isLaoding = true;

      await _basketService.saveBasketItems(
        items: _selectedItems,
        context: context,
      );
      if (mounted) {
        await _commonService.fetchBasketCnt(context, showErrorMsg: false);
      }
    } catch (e) {
      debugPrint('error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('장바구니 추가를 실패하였습니다.')));
      }
    } finally {
      _isLaoding = false;
    }
  }

  /// Item like 상태 토글
  void _toggleLikeState({required Map<String, dynamic> item}) async {
    final itemId = item['itemId'] as int;
    final itemNm = item['itemNm'] as String;
    final like = item['like'] as String? ?? 'N';
    try {
      await _itemService.toggleLikeState(itemId: itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemNm은 관심품목에 ${like == 'Y' ? '추가' : '제외'}하였습니다.'),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: MobileAppBar(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchScreen(keyword: widget.searchKeyword),
            ),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.search),
            SizedBox(width: 6),
            Text(
              '${widget.searchKeyword}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        showNotification: false,
        showSearch: false,
      ),
      bottomSheet: _buildBottomSheet(),
      bottomNavigationBar: const MobileBottomNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Column(
            children: [
              // ─── 상품 리스트 ─────────────────────────────
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_isLaoding) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (_items.isEmpty) {
                      return NoData();
                    }

                    return GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: (_totQty > 0 && _isScrollEnd) ? 80 : 0,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.65,
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
                            });
                            _toggleLikeState(item: item);
                          },
                          onQuantityChanged: (newQty) {
                            setState(() {
                              item['qty'] = newQty.toDouble();
                            });
                          },
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

  /// 하단 바 (선택된 개수·금액 / 장바구니 이동 버튼)
  Widget _buildBottomSheet() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
      height: _totQty > 0 ? 80 : 0,
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

                      if (!mounted) return;

                      // 1. 실제 데이터의 qty를 0으로 초기화
                      for (var item in _items) {
                        item['qty'] = 0.0;
                      }

                      // 2. 카드 UI도 리셋
                      for (final key in _cardKeys) {
                        ItemCardV2.resetByKey(key);
                      }

                      setState(() {}); // UI 업데이트

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('선택된 품목을 장바구니에 추가하였습니다.')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
}
