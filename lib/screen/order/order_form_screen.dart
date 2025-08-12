import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/model/address_model.dart';
import 'package:aetteullo_cust/provider/model/user.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/screen/addr/search_addr_screen.dart';
import 'package:aetteullo_cust/screen/order/order_list_screen.dart';
import 'package:aetteullo_cust/screen/order/order_success_screen.dart';
import 'package:aetteullo_cust/service/order_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/item_card_v3.dart';
import 'package:aetteullo_cust/widget/datepicker/mobile_date_picker.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const OrderFormScreen({super.key, required this.items});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  // ① 메모 옵션을 고정 배열로 보관
  static const List<String> _memoOptions = [
    '빠른배송 요청',
    '문 앞 부탁드립니다',
    '경비실에 맡겨주세요',
  ];

  List<Map<String, dynamic>> _items = [];
  double get _totAmnt => _items.fold(
    0.0,
    (amnt, i) =>
        amnt += (i['bkQty'] as double? ?? 0.0) * (i['price'] as double? ?? 0.0),
  );

  User? user;
  String? _selectedMemo;
  bool _isLoading = false;
  bool _isExpanded = true;
  bool _isInit = true;

  // service
  final OrderService _orderService = OrderService();

  // address state
  String _zipCd = '';
  String _mainAddr = '';
  String _subAddr = '';

  // controller
  final TextEditingController _mainAddressController = TextEditingController();
  final TextEditingController _subAddressController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _deliRqstDatePickerController =
      TextEditingController();

  DateTime? deliRqstDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _selectedMemo ??= _memoOptions.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // 이제 context 사용해도 안전
      user = context.read<UserProvider>().user;

      // 컨트롤러·상태 초기화
      _mainAddressController.text = '';
      _subAddressController.text = user?.addrDtl ?? '';
      _zipCodeController.text = user?.zipCd ?? '';
      _zipCd = user?.zipCd ?? '';
      _mainAddr = user?.addr ?? '';
      _subAddr = user?.addrDtl ?? '';

      _isInit = false;
    }
  }

  @override
  void dispose() {
    _mainAddressController.dispose();
    _subAddressController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _searchAddr() async {
    final juso = await Navigator.push<Juso>(
      context,
      MaterialPageRoute(builder: (_) => SearchAddrScreen()),
    );

    if (juso != null) {
      _zipCodeController.text = juso.zipNo;
      _mainAddressController.text = juso.roadAddr;
      _subAddressController.clear();
    }
  }

  void _submitOrder() async {
    if (_isLoading) return;

    // === Validation ===
    // 1) 장바구니 아이템이 있는지
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('장바구니에 선택된 품목이 없습니다.')));
      return;
    }
    // 2) 주소 입력 확인
    if (_mainAddr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('기본 주소를 입력해주세요.')));
      return;
    }
    if (_subAddr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상세 주소를 입력해주세요.')));
      return;
    }
    // 3) 메모 선택 확인
    if (_selectedMemo == null || _selectedMemo!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('배송 요청사항을 선택해주세요.')));
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      await _orderService.submitOrder(
        items: _items,
        zipCd: _zipCd,
        addr: _mainAddr,
        addrDtl: _subAddr,
        memo: _selectedMemo!,
        deliRqstDate: deliRqstDate ?? DateTime.now(),
        context: context,
      );

      if (mounted) {
        // 1) 스택을 home만 남기고 주문 목록으로 교체
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrderListScreen()),
          (route) => route.isFirst,
        );
        // 2) 주문 성공 화면을 쌓아서, 뒤로 가면 OrderListScreen으로 돌아가도록
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OrderSuccessScreen()));
      }
    } catch (e) {
      debugPrint('error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('주문 제출 중에 에러가 발생하였습니다.')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildSelectWidget({
    String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String hintText = '배송요청사항 선택',
    double borderRadius = 8,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
    Color borderColor = const Color(0xFFCCCCCC),
    Color backgroundColor = Colors.white,
    TextStyle? textStyle,
    Icon? icon,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hintText, style: textStyle),
          isExpanded: true,
          icon:
              icon ??
              const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt, style: textStyle),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void showPostOptionSheet() {
    setState(() {
      _zipCodeController.text = _zipCd;
      _mainAddressController.text = _mainAddr;
      _subAddressController.text = _subAddr;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이를 동적으로 조정할 수 있도록 설정
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드 공간 고려
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: SingleChildScrollView(
                  // 스크롤 가능하도록 설정
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단 바
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '배송지 정보 수정',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '주소',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                              flex: 1,
                              child: _buildTextField(
                                controller: _zipCodeController,
                                onTap: _searchAddr,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              flex: 2,
                              child: _buildTextField(
                                controller: _mainAddressController,
                                onTap: _searchAddr,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '상세주소',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(controller: _subAddressController),
                        const SizedBox(height: 20),
                        // 5) 저장 버튼 (맨 밑에 고정됨)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _zipCd = _zipCodeController.text;
                                _mainAddr = _mainAddressController.text;
                                _subAddr = _subAddressController.text;
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('배송지 정보를 수정하였습니다.'),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '저장',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Container _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: controller,
          focusNode: focusNode, // 포커스 노드를 설정
          onTap: onTap,
          readOnly: onTap != null,
          decoration: const InputDecoration(
            border: InputBorder.none, // 테두리 제거
            isDense: true, // 기본값, 텍스트 필드의 패딩 조정
            isCollapsed: true, // 기본값, 텍스트 필드 크기 조정
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MobileAppBar(
        title: Text(
          '주문',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showBasket: false,
        showNotification: true,
        showSearch: false,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 익스텍션 타일 내부 리스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ExpansionTile(
                initiallyExpanded: _isExpanded,
                title: const Text(
                  '주문상품',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
                // 여기서 toColumn() 이 반환하는 Column 위젯을 리스트에 감싸서 넣어줍니다.
                // ← 여기서 확장/축소 상태 변경 감지
                onExpansionChanged: (expanded) {
                  setState(() => _isExpanded = expanded);
                },
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ItemCardV3(
                        itemNm: item['itemNm'],
                        mnfct: item['mnfct'],
                        qty: item['bkQty'],
                        price: item['price'] as double? ?? 0.0,
                        image: item['image1'],
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Divider();
                    },
                  ),
                ],
              ),
            ),
            Divider(thickness: 5, color: Colors.grey[200]),
            const SizedBox(height: 10),
            // 배송
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '배송지 정보',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.black45,
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () {
                          showPostOptionSheet();
                        },
                        child: const Text('수정'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Text(
                        user?.userNm ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        user?.phone ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ① 이 부분은 고정
                      Text('[$_zipCd] '),
                      // ② 나머지 주소는 남은 영역에서 wrap 가능
                      Expanded(
                        child: Text('$_mainAddr $_subAddr', softWrap: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // ───────────────────────────────────
                  // 배송 요청사항 (제네릭 드롭다운)
                  _GenericDropdown<String>(
                    items: _memoOptions,
                    value: _selectedMemo,
                    itemLabel: (s) => s,
                    hintText: '배송요청사항 선택',
                    onChanged: (v) => setState(() => _selectedMemo = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Divider(thickness: 5, color: Colors.grey[200]),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '배송요청일',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MobileDatePicker(
                      hintText: '배송요청일',
                      initialDate: deliRqstDate,
                      controller: _deliRqstDatePickerController,
                      onChanged: (selectedDate) {
                        setState(() {
                          deliRqstDate = selectedDate;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _submitOrder,
                child: Text(
                  '${formatCurrency(_totAmnt)}원 구매하기',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 스크롤 영역 끝에 안전 영역 여백
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}

/// 제네릭 드롭다운 위젯
/// - T: 옵션의 타입
/// - itemLabel: T → String 변환기 (화면에 보여줄 텍스트)
/// - value: 현재 선택된 값 (nullable)
/// - items: 선택지 리스트
/// - onChanged: 값 변경 콜백
class _GenericDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;
  final String hintText;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color backgroundColor;
  final TextStyle? textStyle;
  final Icon? icon;
  final bool isExpanded;

  const _GenericDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.value,
    this.hintText = '선택하세요',
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderColor = const Color(0xFFCCCCCC),
    this.backgroundColor = Colors.white,
    this.textStyle,
    this.icon,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hintText, style: textStyle),
          isExpanded: isExpanded,
          icon:
              icon ??
              const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), style: textStyle),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
