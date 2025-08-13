import 'package:aetteullo_cust/screen/mypage/itemset/mod_item_set_screen.dart';
import 'package:aetteullo_cust/screen/mypage/itemset/reg_item_set_screen.dart';
import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/item_card_v5.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:aetteullo_cust/widget/nodata/no_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ItemSetListScreen extends StatefulWidget {
  const ItemSetListScreen({super.key});

  @override
  State<ItemSetListScreen> createState() => _ItemSetListScreenState();
}

class _ItemSetListScreenState extends State<ItemSetListScreen> {
  final TextEditingController _setItemNmController = TextEditingController();
  final ItemService _itemService = ItemService();

  bool _isLoading = false;

  List<Map<String, dynamic>> _itemSetList = [];

  List<Map<String, dynamic>> get _selectedItemSetList =>
      _itemSetList.where((its) => (its['selected'] as bool)).toList();

  Future<void> _getItemSetList() async {
    try {
      final responseList = await _itemService.getItemSetList(
        setNm: _setItemNmController.text.trim(),
      );
      _itemSetList = responseList
          .map((itemset) => {...itemset, 'selected': false})
          .toList();
    } catch (e) {
      _itemSetList = [];
      debugPrint('_getItemSetList error: $e');
    } finally {
      setState(() {});
    }
  }

  Widget _bottomSheet() {
    final double? targetHeight = _selectedItemSetList.isNotEmpty ? 80 : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: targetHeight,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.delete, color: Colors.redAccent),
              SizedBox(width: 5),
              Text(
                '선택된 세트: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 5),
              Text(
                '${_selectedItemSetList.length}개',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(
            width: 100,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _deleteItemSet,
              child: Text('삭제'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItemSet() async {
    if (_isLoading || _selectedItemSetList.isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await _itemService.deleteItemSets(
        setIds: _selectedItemSetList.map((its) => its['setId'] as int).toList(),
      );

      setState(() {
        _itemSetList.removeWhere((its) => its['selected'] as bool);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('선택된 아이템 세트가 삭제되었습니다')));
      });
    } on DioException catch (e) {
      debugPrint('error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getItemSetList();
  }

  @override
  void dispose() {
    _setItemNmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '세트 아이템',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showNotification: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onSubmitted: (_) => _getItemSetList(),
                controller: _setItemNmController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(height: 15),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (_itemSetList.isEmpty) {
                    return NoData();
                  }

                  return GridView.builder(
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom: _selectedItemSetList.isNotEmpty ? 90 : 10,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2열
                          crossAxisSpacing: 8, // 열 간격
                          mainAxisSpacing: 8, // 행 간격
                          childAspectRatio: 0.65, // 너비/높이 비율
                        ),
                    itemCount: _itemSetList.length,
                    itemBuilder: (context, index) {
                      final itemSet = _itemSetList[index];
                      // ‘items’ 키를 List<Map<String, dynamic>>로 캐스팅
                      final rawItems = itemSet['items'] as List<dynamic>?;
                      final items = rawItems != null
                          ? List<Map<String, dynamic>>.from(
                              rawItems.map(
                                (e) => Map<String, dynamic>.from(e as Map),
                              ),
                            )
                          : <Map<String, dynamic>>[];

                      // items가 비어있지 않다면 첫 번째 아이템의 image1 사용, 그렇지 않으면 빈 문자열
                      final imgUrl = items.isNotEmpty
                          ? (items.first['image1'] as String? ?? '')
                          : '';

                      return ItemCardV5(
                        imgUrl: imgUrl, // 수정: 첫 번째 아이템 이미지 사용
                        setNm: itemSet['setNm'] as String? ?? '',
                        selected: itemSet['selected'],
                        cnt: items.length.toDouble(),
                        onTap: _selectedItemSetList.isEmpty
                            ? () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ModItemSetScreen(itemSet: itemSet),
                                  ),
                                );
                                await _getItemSetList();
                              }
                            : () {
                                setState(() {
                                  itemSet['selected'] = !itemSet['selected'];
                                });
                              },
                        onLongPress: () {
                          setState(() {
                            itemSet['selected'] = !itemSet['selected'];
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
      floatingActionButton: _selectedItemSetList.isEmpty
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 1,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegItemSetScreen()),
                );
                await _getItemSetList();
              },
              tooltip: '세트 아이템 추가',
              child: const Icon(Icons.add),
            )
          : null,
      bottomSheet: _selectedItemSetList.isNotEmpty ? _bottomSheet() : null,
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
