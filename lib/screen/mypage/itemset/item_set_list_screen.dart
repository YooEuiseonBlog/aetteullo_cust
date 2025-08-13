import 'package:aetteullo_cust/screen/mypage/itemset/mod_item_set_screen.dart';
import 'package:aetteullo_cust/screen/mypage/itemset/reg_item_set_screen.dart';
import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/item_card_v5.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class ItemSetListScreen extends StatefulWidget {
  const ItemSetListScreen({super.key});

  @override
  State<ItemSetListScreen> createState() => _ItemSetListScreenState();
}

class _ItemSetListScreenState extends State<ItemSetListScreen> {
  final TextEditingController _setItemNmController = TextEditingController();
  final ItemService _itemService = ItemService();
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 80,
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
        children: [
          Icon(Icons.delete, color: Colors.red),
          Text(
            '선택된 세트: ',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          Text('test'),
        ],
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModItemSetScreen(itemSet: itemSet),
                        ),
                      );
                      await _getItemSetList();
                    },
                    onLongPress: () {
                      setState(() {
                        itemSet['selected'] = !itemSet['selected'];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
      ),
      bottomSheet: _bottomSheet(),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
