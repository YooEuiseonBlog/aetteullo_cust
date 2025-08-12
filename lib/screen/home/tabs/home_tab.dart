import 'package:aetteullo_cust/constant/default_settings.dart';
import 'package:aetteullo_cust/screen/item/item_screen.dart';
import 'package:aetteullo_cust/screen/order/order_list_screen.dart';
import 'package:aetteullo_cust/service/basket_service.dart';
import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/card/item_card.dart';
import 'package:aetteullo_cust/widget/carousel/asset_carousel.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ItemService _itemService = ItemService();
  final BasketService _basketService = BasketService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendedItems = [];

  Future<void> _saveBasketItem({required Map<String, dynamic> item}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getRandomItemList() async {
    try {
      final rst = await _itemService.getRandomItemList();
      setState(() {
        _recommendedItems = rst;
      });
    } catch (e, stackTrace) {
      debugPrint('[_loadRecommendItemList] Error: $e');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('추천 항목을 불러오는 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getRandomItemList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 캐러셀
          AssetCarousel(items: carouselItems),
          const SizedBox(height: 25),
          // 카테고리 버튼
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories
                    .map(
                      (cat) => CategoryButton(
                        assetPath: cat['assets'] ?? '', // 실제 에셋 경로로 변경
                        label: cat['title'] ?? '',
                        onTap: () {
                          final id = cat['id'];
                          // id가 없으면 아무 동작도 하지 않음
                          if (id == null || id.isEmpty) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderListScreen(
                                title: cat['title'],
                                ctgry: cat['title'] == '전체'
                                    ? null
                                    : cat['title'],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_recommendedItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '추천',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            // 추천 리스트
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recommendedItems.length,
                itemBuilder: (ctx, idx) {
                  final item = _recommendedItems[idx];
                  return ItemCard(
                    imgUrl: item['image1'],
                    title: item['itemNm'],
                    price: item['price'],
                    mnfct: item['mnfct'],
                    originalPrice: item['originalPrice'],
                    rate: item['rate'],
                    promoYn: item['promoYn'],
                    onQuantitySelected: (qty) async {
                      item['qty'] = qty.toDouble();
                      _saveBasketItem(item: item);
                    },
                    onImageTap: () {
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
          const SizedBox(height: 10),
          const Divider(),
          const BusinessInfoSection(),
        ],
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class BusinessInfoSection extends StatelessWidget {
  const BusinessInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 회사명
          Text(
            '팁스밸리(주)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          // 2. 주소
          Text('주소: 서울특별시 금천구 가산디지털2로 70, 5층'),
          SizedBox(height: 4),

          // 3. 대표
          Text('대표: 박상근'),
          SizedBox(height: 4),

          // 4. 사업자 등록번호
          Text('사업자 등록번호: 120-86-38518'),
          SizedBox(height: 4),

          // 5. 통신판매업 신고번호
          Text('통신판매업 신고번호: 2015-서울금천-0312'),
        ],
      ),
    );
  }
}
