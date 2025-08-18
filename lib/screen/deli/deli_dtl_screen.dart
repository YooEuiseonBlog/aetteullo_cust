import 'package:aetteullo_cust/function/color_utils.dart';
import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/provider/com_code_provider.dart';
import 'package:aetteullo_cust/service/deli_service.dart';
import 'package:aetteullo_cust/service/rtn_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/image/custom_cached_network_image.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliDtlScreen extends StatefulWidget {
  final Map<String, dynamic> deliMap;
  const DeliDtlScreen({super.key, required this.deliMap});

  @override
  State<DeliDtlScreen> createState() => _DeliDtlScreenState();
}

class _DeliDtlScreenState extends State<DeliDtlScreen> {
  List<Map<String, dynamic>> _items = [];
  late final List<Map<String, dynamic>> _deliStatList;

  final DeliService _deliService = DeliService();
  final RtnService _rtnService = RtnService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _items = (widget.deliMap['items'] as List<dynamic>)
        .map((i) => Map<String, dynamic>.from(i))
        .toList();
    _deliStatList = context.read<ComCodeProvider>().comCodes['deliStat'] ?? [];
  }

  Future<void> _submitFix({required Map<String, dynamic> item}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      await _deliService.submitFix(item: item);

      // local modify
      item['fixYn'] = 'Y';
      item['fixQty'] = item['deliQty'] as double;

      final itemNm = item['itemNm'];

      final deliStatNm = _deliStatList
          .where((s) => s['key'] == '3')
          .first['name'];
      setState(() {
        widget.deliMap['stat'] = '3';
        widget.deliMap['statNm'] = deliStatNm;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$itemNm이(가) 확정되었습니다.')));
      }
    } on Exception catch (e) {
      debugPrint('$e');
      final itemNm = item['itemNm'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemNm이(가) 확정 중에 에러가 발생하였습니다.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRtn({required Map<String, dynamic> item}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      // api request
      await _rtnService.submitRtn(item: item, memo: '반품 신청');

      // local data modify
      item['fixYn'] = 'Y';
      item['fixQty'] = item['deliQty'] - item['rtnQty'];
      final deliStatNm = _deliStatList
          .where((s) => s['key'] == '3')
          .first['name'];
      setState(() {
        widget.deliMap['stat'] = '3';
        widget.deliMap['statNm'] = deliStatNm;
      });

      final itemNm = item['itemNm'];

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$itemNm이(가) 반품하였습니다.')));
      }
    } on Exception catch (e) {
      debugPrint('$e');
      final itemNm = item['itemNm'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemNm이(가) 반품 중에 에러가 발생하였습니다.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// AlertDialog: 정수 입력 → double 반환
  Future<double?> _askReturnQuantityDialog(
    BuildContext context,
    double maxQty,
  ) {
    final maxInt = maxQty.toInt();
    final controller = TextEditingController(text: maxInt.toString());
    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('반품 수량 입력'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '수량',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[400],
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                final inputInt = int.tryParse(controller.text);
                if (inputInt != null && inputInt > 0 && inputInt <= maxInt) {
                  Navigator.of(ctx).pop(inputInt.toDouble());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('1~최대값 사이의 정수를 입력하세요.')),
                  );
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '배송 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        showSearch: false,
        showBasket: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildExtentSection(
              title: '배송정보',
              isExpanded: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('배송코드'),
                    Text(
                      widget.deliMap['deliCd'] as String? ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('배송업체명'),
                    Text(widget.deliMap['deliComNm'] as String? ?? '-'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('배송 담당자'),
                    Text(widget.deliMap['mngrNm'] as String? ?? '-'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('연락처'),
                    Text(
                      formatPhone(widget.deliMap['mngrPhone'] as String? ?? ''),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('배송일'),
                    Text(
                      formatYyyyMMdd(widget.deliMap['deliDate'] ?? '-', '-'),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('도착 예정일'),
                    Text(
                      formatYyyyMMdd(widget.deliMap['endPlanDate'], '-'),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('도착 예정시간'),
                    Text(
                      formatTime4(
                        widget.deliMap['endPlanTime'] as String? ?? '',
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('배송구분'),
                    Text(
                      widget.deliMap['deliDivNm'] as String? ?? '-',
                      style: TextStyle(
                        color: widget.deliMap['deliDiv'] == '1'
                            ? Colors.red
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('배송상태'),
                    Text(
                      widget.deliMap['statNm'] as String? ?? '-',
                      style: TextStyle(
                        color: getDeliStatColor(widget.deliMap['stat']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// [품목정보 섹션]
            _buildExtentSection(
              title: '품목정보',
              isExpanded: true,
              children: [
                // ListView.separated 하나를 자식으로 넣습니다.
                ListView.separated(
                  // 높이를 자식들 크기에 맞춰 줄이고,
                  shrinkWrap: true,
                  // 내부에서 스크롤 안 되게 막고,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildItemCard(item: item);
                  },
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: Colors.grey, // 구분선 색
                      thickness: 1, // 선 굵기
                      height: 1, // 선 자체가 차지하는 높이
                      indent: 12, // 좌측 여백
                      endIndent: 12, // 우측 여백
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  Widget _buildItemCard({required Map<String, dynamic> item}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${item['itemNm']} ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text('(${item['poNo'] as String? ?? ''})'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCachedNetworkImage(
                width: 100,
                height: 100,
                fit: BoxFit.fill,
                imageUrl: item['image1'],
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(("주문일")),
                          Text(formatYyyyMMdd(item['poDate'], '.')),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(("주문 수량")),
                          Text('${(item['poQty'] as double).toInt()}개'),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('배송 수량'),
                          Text(
                            '${(item['deliQty'] as double).toInt()}개',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.deliMap['stat'] == '3' &&
                          item['fixYn'] == 'Y') ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('확정/반품'),
                            Text(
                              '${(item['fixQty'] as double).toInt()}/${(item['rtnQty'] as double).toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.deliMap['stat'] == '3' && item['fixYn'] == 'N') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await _submitFix(item: item);
                    },
                    child: const Text('확정'),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  fit: FlexFit.tight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      if (_isLoading) return;
                      // maxQty 를 double 로 계산
                      final maxQty =
                          (item['deliQty'] as double) -
                          (item['rtnQty'] as double);
                      final qty = await _askReturnQuantityDialog(
                        context,
                        maxQty,
                      );
                      if (qty != null) {
                        // 실수형으로 담아서 서버에 전송
                        item['rtnQty'] = qty;
                        await _submitRtn(item: item);
                      }
                    },
                    child: const Text('반품'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 공통 Card + ExpansionTile 빌더
  Widget _buildExtentSection({
    required String title,
    required bool isExpanded,
    ValueChanged<bool>? onExpansionChanged,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias, // 또는 Clip.hardEdge
      child: Theme(
        // Divider나 아이콘 색상 등을 세부 조정하기 위해 사용
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 섹션 구분선 제거
        ),
        child: ExpansionTile(
          // 카드 상단(타이틀) 패딩
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 5,
          ),
          // 자식 위젯(children) 패딩
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 5,
          ),
          // 펼쳐졌을 때 배경색
          backgroundColor: Colors.white,
          // 접혀있을 때 배경색
          collapsedBackgroundColor: Colors.white,
          // 펼쳐졌을 때 아이콘 색상
          iconColor: Colors.grey.withValues(alpha: 0.7),
          // 접혀있을 때 아이콘 색상
          collapsedIconColor: Colors.grey.withValues(alpha: 0.7),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          expandedAlignment: Alignment.topLeft,
          children: children,
        ),
      ),
    );
  }
}
