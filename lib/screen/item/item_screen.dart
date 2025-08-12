import 'package:aetteullo_cust/function/etc.dart';
import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/screen/basket/basket_screen.dart';
import 'package:aetteullo_cust/service/basket_service.dart';
import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/button/gradient_button.dart';
import 'package:aetteullo_cust/widget/image/custom_cached_network_image.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool readOnly;

  const ItemScreen({super.key, required this.item, this.readOnly = false});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  Map<String, dynamic> _item = {};
  final ItemService _itemService = ItemService();
  final BasketService _basketService = BasketService();

  // 읽기 전용 상태
  bool readOnly = false;

  // 좋아요 버튼 실행 상태 플래그
  bool _isLoading = false;

  // 현재 선택된 이미지 인덱스
  int selectedImageIndex = 0;

  // 유효한 이미지 URL 리스트
  late List<String> itemImages;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (_item['qty'] == null) {
      _item['qty'] = 0.0;
    }
    readOnly = widget.readOnly;

    // 모든 이미지 URL을 수집하고 빈 문자열은 제외
    final rawImages = <String>[
      _item['image1'] ?? '',
      _item['image2'] ?? '',
      _item['image3'] ?? '',
      _item['image4'] ?? '',
      _item['image5'] ?? '',
    ];
    itemImages = rawImages.where((url) => url.isNotEmpty).toList();
  }

  Future<void> _saveBasketItems() async {
    var msg = '';
    if (_isLoading) return;

    if (_item['qty'] <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수량이 0개 이상이어야 합니다.')));
      return;
    }

    _isLoading = true;

    try {
      await _basketService.saveBasketItems(items: [_item], context: context);
      msg = "장바구니에 품목을 추가했습니다.";
    } on DioException catch (e) {
      debugPrint("error: $e");
      msg = "장바구니 추가 중에 문제가 발생하였습니다. 잠시 후에 다시 시도해주세요.";
    } finally {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("장바구니 이동"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text(msg), const Text("장바구니로 이동하시겠습니까?")],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그만 닫기
                  setState(() {
                    _item['qty'] = 0;
                  });
                },
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BasketScreen(),
                    ),
                  );
                },
                child: const Text("확인"),
              ),
            ],
          ),
        );
      }
      _isLoading = false;
    }
  }

  void _handleLikeButton() async {
    if (_isLoading) return;
    _isLoading = true;

    // 서버 API 호출
    try {
      await _itemService.toggleLikeState(itemId: _item['itemId']);

      // 로컬 상태 토글
      setState(() {
        _item['like'] = _item['like'] == 'Y' ? 'N' : 'Y';
        if (mounted) {
          final itemNm = _item['itemNm'] as String? ?? '';
          final message = getLikeMessage(itemNm, _item['like'] as String);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      });
    } on Exception catch (e) {
      debugPrint('_handleLikeButton error: $e');
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = formatCurrency(_item['price']);

    final existingCategories = [
      _item['mainCtgry'],
      _item['midCtgry'],
      _item['subCtgry'],
    ].where((c) => c.isNotEmpty).join('/');

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: const MobileAppBar(title: '품목 정보', showNotification: false),
      bottomNavigationBar: const MobileBottomNavigationBar(),
      body: Column(
        children: [
          // 상단 이미지와 썸네일을 겹치기 위한 Stack 영역
          Container(
            width: MediaQuery.of(context).size.width,
            height: 350,
            color: Colors.black12,
            child: Stack(
              children: [
                // 큰 이미지
                Positioned.fill(
                  child: itemImages.isNotEmpty
                      ? CustomCachedNetworkImage(
                          width: MediaQuery.of(context).size.width,
                          height: 300,
                          imageUrl: itemImages[selectedImageIndex],
                          fit: BoxFit.cover,
                          onError: (url, error) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() {
                                itemImages.remove(url);
                                if (selectedImageIndex >= itemImages.length) {
                                  selectedImageIndex = itemImages.isNotEmpty
                                      ? 0
                                      : -1;
                                }
                              });
                            });
                          },
                          placeholder: Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: Container(
                            color: Colors.grey,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                // 썸네일 행 (이미지 하단에 반투명 배경으로 겹침)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(itemImages.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImageIndex = index;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Stack(
                              children: [
                                CustomCachedNetworkImage(
                                  width: 50,
                                  height: 50,
                                  imageUrl: itemImages[index],
                                  onError: (url, error) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (!mounted) return;
                                          setState(() {
                                            itemImages.remove(url);
                                            if (selectedImageIndex >=
                                                itemImages.length) {
                                              selectedImageIndex =
                                                  itemImages.isNotEmpty
                                                  ? 0
                                                  : -1;
                                            }
                                          });
                                        });
                                  },
                                  placeholder: Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: Container(
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // 선택 여부에 따라 투명도 조절하는 검정 오버레이
                                Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.black.withOpacity(
                                    selectedImageIndex == index ? 0.1 : 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 품목 정보 영역
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 28, left: 24, right: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // 그림자 색상 및 투명도
                    spreadRadius: 2, // 그림자의 확산 정도
                    blurRadius: 5, // 그림자의 흐림 정도
                    offset: const Offset(0, -1), // 그림자의 위치 조정 (x, y)
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 품목명과 좋아요 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _item['itemNm'],
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!readOnly)
                        IconButton(
                          icon: Icon(
                            _item['like'] == 'Y'
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _item['like'] == 'Y'
                                ? Colors.red
                                : Colors.grey,
                            size: 30,
                          ),
                          onPressed: _handleLikeButton,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$formattedPrice 원',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.item['promoYn'] == 'Y') ...[
                            const SizedBox(width: 10),
                            const Chip(
                              backgroundColor: Colors.green,
                              elevation: 0,
                              side: BorderSide.none,
                              labelStyle: TextStyle(color: Colors.white),
                              label: Text('할인'),
                            ),
                          ],
                        ],
                      ),
                      if (!readOnly) buildItemQtyControl(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  // 상세 정보
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          buildRowInfo(label: '카테고리', info: existingCategories),
                          const SizedBox(height: 4),
                          buildRowInfo(label: '단위', info: '${_item['unitNm']}'),
                          const SizedBox(height: 4),
                          buildRowInfo(
                            label: '원산지/제조사',
                            info: '${_item['origin']}/${_item['mnfct']}',
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  // Spacer 추가하여 버튼을 하단에 고정
                  const SizedBox(height: 20),
                  if (!readOnly)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GradientButton(
                        title: '장바구니 담기',
                        onTap: () => _saveBasketItems(),
                      ),
                    ),
                  const SizedBox(height: 20), // 버튼과 화면 하단 사이 간격
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildItemQtyControl() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        border: Border.all(style: BorderStyle.none),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (_item['qty'] > 0) {
                  _item['qty'] -= 1.0;
                }
              });
            },
            child: Icon(Icons.remove, color: Colors.grey.withOpacity(0.5)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 1,
                  spreadRadius: 1,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Text(
              '${(_item['qty'] as double? ?? 0.0).toInt()}',
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              setState(() {
                _item['qty'] += 1.0;
              });
            },
            child: Icon(Icons.add, color: Colors.grey.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Row buildRowInfo({required String label, required String info}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Expanded(
          flex: 2,
          child: Text(info, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
