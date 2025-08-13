import 'package:aetteullo_cust/service/item_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/check_item_v3.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class ModItemSetScreen extends StatefulWidget {
  final Map<String, dynamic> itemSet;
  const ModItemSetScreen({super.key, required this.itemSet});

  @override
  State<ModItemSetScreen> createState() => _ModItemSetScreenState();
}

class _ModItemSetScreenState extends State<ModItemSetScreen> {
  final TextEditingController _setNmController = TextEditingController();
  late final Map<String, dynamic> _itemSet;

  List<Map<String, dynamic>> get _items =>
      (_itemSet['items'] as List<dynamic>).cast<Map<String, dynamic>>();

  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _itemList = [];
  final ItemService _itemService = ItemService();

  bool _isLoading = false;

  /// 1) “선택된 아이템이 하나라도 있는지” 확인
  bool get _hasSelection => _itemList.any((item) => item['isChecked'] as bool);

  /// 2) “기존 세트 이름과 아이템”과 비교하여 변경사항이 있는지 확인
  bool get _isUnchanged {
    // 기존 세트 이름
    final originalName = widget.itemSet['setNm'] as String? ?? '';
    // 현재 입력된 세트 이름
    final currentName = _setNmController.text.trim();
    if (originalName != currentName) {
      return false; // 이름이 다르면 변경된 상태
    }

    // 기존에 세트에 포함된 아이템 ID 집합
    final originalIds = _items.map((e) => e['itemId'] as int).toSet();

    // 현재 체크된 아이템 ID 집합
    final currentIds = _itemList
        .where((item) => item['isChecked'] as bool)
        .map((e) => e['itemId'] as int)
        .toSet();

    // 길이가 같고, 차집합이 비어있으면(완전히 동일) ⇒ 변경 없음
    return originalIds.length == currentIds.length &&
        currentIds.difference(originalIds).isEmpty;
  }

  Future<void> _getItemList() async {
    try {
      final List<Map<String, dynamic>> currItemSetItems = _items;
      final selectedIds = currItemSetItems
          .map((e) => e['itemId'] as int) // 서버에서 내려준 'itemId' 키 사용
          .toSet();

      final respItemList = await _itemService.searchItemList();

      _itemList = respItemList.map((item) {
        final newMap = <String, dynamic>{
          ...item,
          'isChecked': selectedIds.contains(item['itemId']),
        };
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
      setState(() {}); // 포커스 변화 시 리빌드
    });

    _itemSet = Map.from(widget.itemSet);

    // 세트 명 세팅
    _setNmController.text = widget.itemSet['setNm'] as String? ?? '';
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

  void _updateItemSet() async {
    if (_isLoading) return;
    _isLoading = true;

    // 1) 세트 이름 비어있는지
    final currentName = _setNmController.text.trim();
    if (currentName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('세트 이름이 입력되지 않았습니다.')));
      setState(() => _isLoading = false);
      return;
    }

    // 2) 체크된 아이템이 하나라도 있는지
    final selectedItems = _itemList
        .where((item) => item['isChecked'] as bool)
        .toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('품목이 선택되지 않았습니다.')));
      setState(() => _isLoading = false);
      return;
    }

    // 3) 변경 사항이 없는 경우 막기
    if (_isUnchanged) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('변경된 사항이 없습니다.')));
      setState(() => _isLoading = false);
      return;
    }

    // 4) 실제 저장 로직
    try {
      await _itemService.updateItemSet(
        items: selectedItems,
        setNm: currentName,
        setId: widget.itemSet['setId'] as int,
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
      appBar: MobileAppBar(
        title: Text(
          widget.itemSet['setNm'] as String? ?? '',
          style: const TextStyle(
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
              onChanged: (_) {
                // 이름이 바뀌면 버튼 활성/비활성 상태도 바뀌도록 리빌드
                setState(() {});
              },
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
                  // 3) _isUnchanged가 true면 onPressed: null → 버튼이 비활성화(회색) 됩니다.
                  ElevatedButton(
                    onPressed: _isUnchanged ? null : _updateItemSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUnchanged
                          ? Colors.grey
                          : const Color(0xFF0CC277),
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isUnchanged ? Colors.white70 : Colors.white,
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
