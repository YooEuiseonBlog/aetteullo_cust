import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/check_item_v3.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class RegItemSetScreen extends StatefulWidget {
  const RegItemSetScreen({super.key});

  @override
  State<RegItemSetScreen> createState() => _RegItemSetScreenState();
}

class _RegItemSetScreenState extends State<RegItemSetScreen> {
  final TextEditingController _setNmController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _itemList = [];
  final ItemService _itemService = ItemService();

  bool _isLoading = false;

  bool get _hasSelection => _itemList.any((item) => item['isChecked'] as bool);

  Future<void> _getItemList() async {
    try {
      final respItemList = await _itemService.searchItemList();

      _itemList = respItemList.map((i) {
        final newMap = <String, dynamic>{...i, 'isChecked': false};
        return newMap;
      }).toList();
    } on Exception catch (e) {
      _itemList = <Map<String, dynamic>>[];
      debugPrint('_getItemList error: $e');
    } finally {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });

    _getItemList();
  }

  @override
  void dispose() {
    _setNmController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSelection() {
    for (var item in _itemList) {
      item['isChecked'] = false;
    }
    setState(() {});
  }

  void _saveItemSet() async {
    if (_isLoading) return;
    _isLoading = true;

    if (_setNmController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('세트 이름이 입력되지 않았습니다.')));
      return;
    }

    final selectedItems = _itemList
        .where((item) => item['isChecked'] as bool)
        .toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('품목이 선택되지 않았습니다.')));
      return;
    }

    try {
      await _itemService.saveItemSet(
        items: selectedItems,
        setNm: _setNmController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('세트가 등록되었습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('_saveItemSet error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '세트 등록',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '품목',
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
                ),
                InkWell(
                  onTap: _clearSelection,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.only(
                  bottom: _hasSelection ? 80 : 0, // bottomSheet 높이만큼 패딩
                ),
                itemCount: _itemList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2열
                  crossAxisSpacing: 8, // 열 간격
                  mainAxisSpacing: 8, // 행 간격
                  childAspectRatio: 0.80, // 너비/높이 비율
                ),
                itemBuilder: (context, index) {
                  final item = _itemList[index];
                  return CheckItemCardV3(
                    isSelected: item['isChecked'],
                    itemName: item['itemNm'],
                    qty: 1,
                    imageUrl: item['image1'],
                    onSelected: (value) {
                      setState(() {
                        item['isChecked'] = value;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomSheet(),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    final isFocused = _focusNode.hasFocus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '세트 이름',
            style: TextStyle(
              fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: _setNmController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '세트 이름',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    final selectedCount = _itemList
        .where((item) => item['isChecked'] as bool)
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
      height: _hasSelection ? 80 : 0,
      child: _hasSelection
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
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '$selectedCount개 선택',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saveItemSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0CC277),
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
