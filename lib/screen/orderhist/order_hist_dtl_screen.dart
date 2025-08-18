import 'package:aetteullo_cust/function/color_utils.dart';
import 'package:aetteullo_cust/screen/orderhist/order_hist_dtl_cncl_screen.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/button/gradient_button.dart';
import 'package:aetteullo_cust/widget/image/custom_cached_network_image.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistDtlScreen extends StatefulWidget {
  final Map<String, dynamic> orderInfo;
  const OrderHistDtlScreen({super.key, required this.orderInfo});

  @override
  State<OrderHistDtlScreen> createState() => _OrderHistDtlScreenState();
}

class _OrderHistDtlScreenState extends State<OrderHistDtlScreen> {
  /// 각 섹션이 열리고 닫히는 상태를 관리하는 변수
  final bool _initExpanded = true; // 배송정보 섹션 접힘/펼침 상태
  final bool _isItemInfoExpanded = true; // 품목정보 섹션 접힘/펼침 상태
  final _formatter = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '',
    decimalDigits: 0,
  );

  String formatYmd(String? ymd, String sep) {
    if (ymd != null) {
      if (ymd.length != 8) {
        // 길이가 8이 아니면 그대로 반환하거나 예외 던지기
        return ymd;
      }
      final y = ymd.substring(0, 4);
      final m = ymd.substring(4, 6);
      final d = ymd.substring(6, 8);
      return [y, m, d].join(sep);
    }

    return '-';
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty || time == '-') return '-';
    final parts = time.split(':');
    if (parts.length != 2) return time;
    return '${parts[0]}시 ${parts[1]}분';
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.orderInfo['item'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return Scaffold(
      // 상단 AppBar
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '주문 상세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showSearch: false,
        showBasket: false,
      ),
      // 내용 영역
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              /// [배송정보 섹션]
              _buildExtentSection(
                title: '주문정보',
                isExpanded: _initExpanded,
                children: [
                  _buildInfoRow(label: '주문번호', value: widget.orderInfo['poNo']),
                  _buildInfoRow(
                    label: '메모',
                    value: widget.orderInfo['deliMemo'],
                  ),
                  _buildInfoRow(
                    label: '배송 요청일',
                    value: formatYmd(widget.orderInfo['deliRqstDate'], '.'),
                  ),
                  _buildInfoRow(
                    label: '주소',
                    value:
                        '${(widget.orderInfo['zipCd'] as String? ?? '').isNotEmpty ? '[${widget.orderInfo['zipCd']}]' : ''} ${widget.orderInfo['addr']}',
                  ),
                  _buildInfoRow(
                    label: '상세주소',
                    value: widget.orderInfo['addrDtl'] as String? ?? '',
                  ),
                  _buildInfoRow(
                    label: '연락처',
                    value: widget.orderInfo['recUserPhone'],
                  ),
                  _buildInfoRow(
                    label: '주문일',
                    value: widget.orderInfo['poDate'],
                  ),
                  _buildInfoRow(
                    label: '상태',
                    value: Text(
                      widget.orderInfo['statNm'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: getPoStatusColor(widget.orderInfo['stat']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.orderInfo['stat'] == '8')
                _buildExtentSection(
                  title: '취소정보',
                  isExpanded: _initExpanded,
                  children: [
                    _buildInfoRow(
                      label: '취소일',
                      value: formatYmd(widget.orderInfo['clDate'], '.'),
                    ),
                    _buildInfoRow(
                      label: '취소사항',
                      value: Text(
                        widget.orderInfo['clMemo'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 10),

              /// [품목정보 섹션]
              _buildExtentSection(
                title: '품목정보',
                isExpanded: _isItemInfoExpanded,
                children: [
                  // ListView.separated 하나를 자식으로 넣습니다.
                  ListView.separated(
                    // 높이를 자식들 크기에 맞춰 줄이고,
                    shrinkWrap: true,
                    // 내부에서 스크롤 안 되게 막고,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
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
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        title: '뒤로가기',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (widget.orderInfo['fixYn'] == 'N')
                      Expanded(
                        child: GradientButton(
                          mode: ButtonMode.alert,
                          title: '취소',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderHistDtlCnclScreen(
                                  orderInfo: widget.orderInfo,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  Widget _buildItemCard({required Map<String, dynamic> item}) {
    final formattedAmnt = _formatter.format(item['amnt'] ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['itemNm'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                          const Text('가격'),
                          Text(
                            '$formattedAmnt원',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(("수량")),
                          Text('${(item['qty'] as double? ?? 0.0).toInt()}개'),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text(("단위")), Text(item['unitNm'])],
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            horizontal: 16.0,
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
          children: children,
        ),
      ),
    );
  }

  /// '레이블 - 값' 형태의 정보를 한 줄씩 표시하는 헬퍼 메서드
  Widget _buildInfoRow({required String label, required dynamic value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (value is String)
            Text(value, style: const TextStyle(fontSize: 14)),
          if (value is Widget) value,
        ],
      ),
    );
  }
}
