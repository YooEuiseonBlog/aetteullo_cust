import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  // initialCategories 타입을 Map 리스트로 변경
  final List<Map<String, dynamic>> initialCategories;
  final List<Map<String, dynamic>>? mainCtgry;
  final List<Map<String, dynamic>>? midCtgry;
  final List<Map<String, dynamic>>? subCtgry;
  final RangeValues initialRange;
  final void Function(List<Map<String, dynamic>> categories, RangeValues? range)
  onApply;

  const FilterSheet({
    super.key,
    this.initialCategories = const <Map<String, dynamic>>[],
    this.initialRange = const RangeValues(0, 100000),
    required this.onApply,
    required this.mainCtgry,
    required this.midCtgry,
    required this.subCtgry,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['카테고리', '가격'];
  late List<Map<String, dynamic>> _mainCategories;
  // late List<Map<String, dynamic>> _midCategories;
  // late List<Map<String, dynamic>> _subCategories;
  // _selectedCategories 타입도 Map 리스트로 변경
  late List<Map<String, dynamic>> _selectedCategories;
  late RangeValues _selectedRange;
  static const double _rangeMin = 0;
  static const double _rangeMax = 100000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Map 리스트 복사
    _selectedCategories = List<Map<String, dynamic>>.from(
      widget.initialCategories,
    );
    _selectedRange = widget.initialRange;
    _mainCategories = widget.mainCtgry ?? [];
    // _midCategories = widget.midCtgry ?? [];
    // _subCategories = widget.subCtgry ?? [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(double value) {
    final v = value.toInt();
    if (v >= _rangeMax) return '$v원+';
    return '$v원';
  }

  bool get _hasCustomRange =>
      _selectedRange.start != _rangeMin || _selectedRange.end != _rangeMax;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.6,
      initialChildSize: 0.6,
      maxChildSize: 0.6,
      builder: (context, scrollCtr) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '필터',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
              labelColor: Colors.black87,
              indicatorColor: Colors.green,
            ),
            const SizedBox(height: 10),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── 카테고리 탭 ──
                  ListView(
                    controller: scrollCtr,
                    dragStartBehavior: DragStartBehavior.down,
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        '카테고리',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _mainCategories.map((cat) {
                          final selected = _selectedCategories.contains(cat);
                          return _MobileFilterChip(
                            label: cat['name'],
                            selected: selected,
                            onSelected: (sel) => setState(() {
                              sel
                                  ? _selectedCategories.add(cat)
                                  : _selectedCategories.remove(cat);
                            }),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // ── 가격대 탭 ──
                  ListView(
                    controller: scrollCtr,
                    dragStartBehavior: DragStartBehavior.down,
                    padding: EdgeInsets.zero,
                    children: [
                      const Text(
                        '가격대',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _selectedRange,
                        min: _rangeMin,
                        max: _rangeMax,
                        divisions: 20,
                        labels: RangeLabels(
                          _formatPrice(_selectedRange.start),
                          _formatPrice(_selectedRange.end),
                        ),
                        activeColor: Colors.green,
                        onChanged: (r) => setState(() => _selectedRange = r),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_formatPrice(_selectedRange.start)),
                          ),
                          const Text('~'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_formatPrice(_selectedRange.end)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 선택된 Chip
            if (_selectedCategories.isNotEmpty || _hasCustomRange) ...[
              const Divider(),
              SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var cat in _selectedCategories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _MobileChip(
                              label: cat['name'],
                              onDeleted: () => setState(
                                () => _selectedCategories.remove(cat),
                              ),
                            ),
                          ),
                        if (_hasCustomRange)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _MobileChip(
                              label:
                                  '${_formatPrice(_selectedRange.start)} ~ ${_formatPrice(_selectedRange.end)}',
                              onDeleted: () => setState(
                                () => _selectedRange = widget.initialRange,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // 적용 버튼
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final sendRange = _hasCustomRange ? _selectedRange : null;
                  widget.onApply(_selectedCategories, sendRange);
                  Navigator.of(context).pop();
                },
                child: const Text('적용'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileFilterChip extends StatelessWidget {
  /// 칩에 표시할 텍스트
  final String label;

  /// 선택 여부
  final bool selected;

  /// 선택/해제 시 호출될 콜백
  final ValueChanged<bool> onSelected;

  const _MobileFilterChip({
    required this.label,
    this.selected = false,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.transparent : Colors.grey.shade400,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      selected: selected,
      showCheckmark: false,
      selectedColor: Colors.green.withValues(alpha: 0.7),
      onSelected: onSelected,
    );
  }
}

class _MobileChip extends StatelessWidget {
  /// Chip에 표시할 텍스트
  final String label;

  /// 삭제(닫기) 버튼이 눌렸을 때 호출되는 콜백
  final VoidCallback? onDeleted;

  const _MobileChip({required this.label, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      deleteIcon: const Icon(Icons.close, size: 18),
      deleteIconColor: Colors.black,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onDeleted: onDeleted,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
