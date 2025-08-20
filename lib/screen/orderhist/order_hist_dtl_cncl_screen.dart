import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/screen/orderhist/order_cncl_success_screen.dart';
import 'package:aetteullo_cust/screen/orderhist/order_hist_screen.dart';
import 'package:aetteullo_cust/service/order_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/button/gradient_button.dart';
import 'package:aetteullo_cust/widget/etc/custom_container.dart';
import 'package:aetteullo_cust/widget/image/custom_cached_network_image.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistDtlCnclScreen extends StatefulWidget {
  final Map<String, dynamic> orderInfo;
  const OrderHistDtlCnclScreen({super.key, required this.orderInfo});

  @override
  State<OrderHistDtlCnclScreen> createState() => _OrderHistDtlCnclScreenState();
}

class _OrderHistDtlCnclScreenState extends State<OrderHistDtlCnclScreen> {
  bool _isLoading = false;

  final _formatter = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '',
    decimalDigits: 0,
  );

  String? _selectedCancelReason;
  final TextEditingController _cancelDateController = TextEditingController();
  final TextEditingController _cancelDetailController = TextEditingController();
  bool isExpanded = true;

  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    // DateFormat을 이용해 'yyyy-MM-dd' 형태로 변환
    final formatter = DateFormat('yyyy-MM-dd');
    _cancelDateController.text = formatter.format(now);
  }

  @override
  void dispose() {
    _cancelDateController.dispose();
    _cancelDetailController.dispose();
    super.dispose();
  }

  /// 주문 취소 API를 호출하고 후속 처리를 수행하는 메서드입니다.
  Future<void> _handleCancelOrder() async {
    if (_isLoading) return;

    // 버튼 비활성화 처리
    setState(() {
      _isLoading = true;
    });

    // 취소 사유가 null 또는 빈 문자열인 경우 검증
    if (_selectedCancelReason == null ||
        _selectedCancelReason!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('취소 사유를 선택해주세요.')));
      // 버튼 활성화 및 함수 종료
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 2) 상세 사유 검증
    if (_selectedCancelReason == '직접 입력' &&
        _cancelDetailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상세 사유를 입력해주세요.')));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final memo = _selectedCancelReason == '직접 입력'
        ? _cancelDetailController.text.trim()
        : _selectedCancelReason!;

    try {
      await _orderService.submitCancel(
        poNo: widget.orderInfo['poNo'],
        memo: memo,
      );

      final cancelInfo = {
        ...widget.orderInfo,
        'stat': '8',
        'statNm': '발주 취소',
        'clMemo': memo,
        'clDate': toYyyyMMdd(DateTime.now()),
        'fixYn': 'Y',
      };

      if (mounted) {
        // 홈 화면까지 팝 후 성공 화면으로
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrderHistScreen(tabIdx: 1)),
          (route) => route.isFirst,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderCnclSuccessScreen(cancelInfo: cancelInfo),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('주문 취소에 실패하였습니다.')));
      }
    } finally {
      // API 호출이 끝난 후 버튼을 다시 활성화
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.orderInfo['item'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '주문 취소',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        showSearch: false,
        showBasket: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildExtentSection(
              onExpansionChanged: (value) {
                setState(() {
                  isExpanded = value;
                });
              },
              title: '취소 상품',
              isExpanded: isExpanded,
              children: [
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
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12); // 구분 간격
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildCancelInfoSection(),
            const SizedBox(height: 10),
            if (_selectedCancelReason == '직접 입력') _buildTextField(),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            _buildSummarySection(items: items),
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  Widget _buildItemCard({required Map<String, dynamic> item}) {
    final formattedAmnt = _formatter.format(item['amnt'] as double? ?? 0.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['itemNm'] ?? '-',
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
                imageUrl: item['image1'] ?? '',
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
                        children: [
                          const Text(("단위")),
                          Text(item['unitNm'] as String? ?? ''),
                        ],
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

  Widget _buildExtentSection({
    required String title,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
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

  Container _buildSummarySection({required List<Map<String, dynamic>> items}) {
    final amnt = items.fold(0.0, (acc, curr) => curr['amnt'] + acc);
    final cnt = items.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: '총 ',
              style: const TextStyle(fontSize: 16, color: Colors.black),
              children: [
                TextSpan(
                  text: '$cnt건',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSubmitSection(amnt),
        ],
      ),
    );
  }

  Widget _buildSubmitSection(double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('총 취소금액', style: TextStyle(fontSize: 16)),
            Text(
              '${formatCurrency(amount)}원',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: GradientButton(
                title: '취소',
                onTap: _isLoading ? () {} : () => _handleCancelOrder(),
                mode: ButtonMode.alert,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// "취소정보" 섹션 위젯 메서드
  Widget _buildCancelInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                // 1) 취소사유
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Flexible(
                          fit: FlexFit.tight,
                          child: Text('취소사유', style: TextStyle(fontSize: 16)),
                        ),
                        Flexible(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isDense: true,
                            // border, enabledBorder, focusedBorder를 모두 동일하게 설정
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                            value: _selectedCancelReason,
                            hint: const Text('취소사유'),
                            items:
                                const [
                                  '고객 변심',
                                  '상품 불량',
                                  '배송 지연',
                                  '기타',
                                  '직접 입력',
                                ].map((reason) {
                                  return DropdownMenuItem<String>(
                                    value: reason,
                                    child: Text(reason),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCancelReason = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 2) 취소요청일
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Flexible(
                          fit: FlexFit.tight,
                          child: Text('취소요청일', style: TextStyle(fontSize: 16)),
                        ),
                        Flexible(
                          flex: 2,
                          child: TextFormField(
                            controller: _cancelDateController,
                            readOnly: true, // 직접 입력 방지, 탭 이벤트만 처리
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: '날짜 선택',
                              suffixIcon: Icon(Icons.calendar_today),
                              // 모든 Border를 동일한 스타일로 지정
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: _cancelDetailController,
        maxLines: 3,
        maxLength: 200,
        decoration: InputDecoration(
          isDense: true,
          hintText: '상세 사유를 입력해주세요.',
          prefixIcon: const Icon(Icons.edit),
          counterText: '${_cancelDetailController.text.length}/200',
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
