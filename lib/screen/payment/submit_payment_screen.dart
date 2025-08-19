import 'dart:math';

import 'package:aetteullo_cust/constant/constants.dart';
import 'package:aetteullo_cust/formatter/formatter.dart';
import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/screen/payment/payment_form_web_view.dart';
import 'package:aetteullo_cust/screen/payment/payment_success_screen.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:aetteullo_cust/service/payment_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SubmitPaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> payments;
  const SubmitPaymentScreen({super.key, required this.payments});

  @override
  State<SubmitPaymentScreen> createState() => _SubmitPaymentScreenState();
}

enum PaymentMethod { vAccount, card, transfer }

class _SubmitPaymentScreenState extends State<SubmitPaymentScreen> {
  static const String _baseUrl = API_BASE_URL;
  bool _isLoading = false;
  late final List<Map<String, dynamic>> _payments;
  double _prePymAmnt = 0.0;
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _limitAmntCtrl = TextEditingController();
  final TextEditingController _unLimitAmntCtrl = TextEditingController();
  bool _isUsedPrePymAmt = false;

  String get _partnerCd => _payments.first['partnerCd'];
  double get _totRmnAmnt => _payments.fold<double>(
    0.0,
    (acc, p) => acc + ((p['rmnAmnt'] as num?)?.toDouble() ?? 0.0),
  );

  double get _realRmnAmnt => _isUsedPrePymAmt
      ? (_totRmnAmnt - _prePymAmnt) >= 0
            ? (_totRmnAmnt - _prePymAmnt)
            : 0.0
      : _totRmnAmnt;

  double get _usePrePymAmt => min(_prePymAmnt, _totRmnAmnt);

  PaymentMethod? _selectedMethod;

  // 클래스 대신 맵으로 옵션 관리
  final List<Map<String, Object>> _options = const [
    {
      'method': PaymentMethod.vAccount,
      'label': '가상계좌',
      'icon': Icons.account_balance,
    },
    {'method': PaymentMethod.card, 'label': '신용카드', 'icon': Icons.credit_card},
    {
      'method': PaymentMethod.transfer,
      'label': '실시간 이체',
      'icon': Icons.swap_horiz,
    },
  ];

  Future<void> _loadPrePymAmt() async {
    final rawMap = await _paymentService.selectPrePym();
    final amt = (rawMap['amt'] as int? ?? 0).toDouble();
    setState(() {
      _prePymAmnt = amt;
    });
  }

  @override
  void initState() {
    super.initState();
    _payments = [...widget.payments.cast<Map<String, dynamic>>()];
    _loadPrePymAmt();
    _unLimitAmntCtrl.text = formatCurrency(_realRmnAmnt);
    _limitAmntCtrl.text = formatCurrency(_realRmnAmnt);
  }

  @override
  void dispose() {
    _limitAmntCtrl.dispose();
    _unLimitAmntCtrl.dispose();
    super.dispose();
  }

  String _pathOf(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return '/v1/inicis/n/card/form';
      case PaymentMethod.transfer:
        return '/v1/inicis/n/bank/form';
      case PaymentMethod.vAccount:
        return '/v1/inicis/n/vbank/form';
    }
  }

  double _parseAmount(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll(',', '').trim()) ?? 0.0;
  }

  void _clampLimitAmount() {
    final curr = _parseAmount(_limitAmntCtrl.text);
    final clamped = curr > _realRmnAmnt ? _realRmnAmnt : curr;

    final formatted = formatCurrency(clamped);
    if (_limitAmntCtrl.text != formatted) {
      setState(() {
        _limitAmntCtrl.text = formatted;
      });
      // // 커서를 맨 뒤로 이동
      // _limitAmntCtrl.selection = TextSelection.fromPosition(
      //   TextPosition(offset: _limitAmntCtrl.text.length),
      // );
    }
  }

  Future<void> _onPay() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      if (_selectedMethod == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('결제 수단을 선택하세요.')));
        return;
      }

      var amt = (_selectedMethod == PaymentMethod.transfer)
          ? _parseAmount(_unLimitAmntCtrl.text).toInt()
          : _parseAmount(_limitAmntCtrl.text).toInt();

      if (_selectedMethod != PaymentMethod.transfer) {
        amt = min(amt.toDouble(), _realRmnAmnt).toInt();
      }

      if (_prePymAmnt <= 0 && amt <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('결제 금액이 없습니다.')));
        return;
      }

      final user = context.read<UserProvider>().user;
      if (amt > 0) {
        final path = _pathOf(_selectedMethod!);
        final uri = Uri.parse('$_baseUrl$path').replace(
          queryParameters: {
            'amt': amt.toString(),
            'prdNm': '${user.industNm}_대금',
            'byrNm': user.userNm,
            'byrMblNo': user.phone,
            'byrEmail': user.email,
            'industCd': user.industCd,
            'ptnrCd': _partnerCd,
          },
        );

        // 쿠키 Jar 에서 JWT_TOKEN 꺼냄 (DioCookieClient 싱글톤)
        final jwt = await DioCookieClient().getJwtToken();

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFormWebView(
              url: uri.toString(),
              bearerToken: jwt, // ← WebView로 넘김 (첫 요청 헤더에 붙음)
            ),
          ),
        );
      } else {
        await _paymentService.payPrePymAmt(
          ptnrCd: _partnerCd,
          amt: _totRmnAmnt.toInt(),
          prdNm: '${user.industNm}_대금',
          byrNm: user.userNm,
          byrMblNo: user.phone,
          byrEmail: user.email,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentSuccessScreen()),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MobileAppBar(title: '결제하기'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('결제금액', style: TextStyle(fontSize: 16)),
                  Text(
                    '${formatCurrency(_totRmnAmnt)}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _isUsedPrePymAmt,
                        onChanged: _prePymAmnt > 0
                            ? (val) {
                                setState(() {
                                  debugPrint('$val');
                                  _isUsedPrePymAmt = val!;
                                });
                                _clampLimitAmount();
                              }
                            : null,
                      ),
                      Text(
                        '선수금',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _isUsedPrePymAmt
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${formatCurrency(_prePymAmnt)}원',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isUsedPrePymAmt ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '- 사용 선수금',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _isUsedPrePymAmt
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${formatCurrency(_isUsedPrePymAmt ? _usePrePymAmt : 0.0)}원',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _isUsedPrePymAmt ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '최종 결제금액',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${formatCurrency(_realRmnAmnt)}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              const Divider(height: 20, thickness: 3),
              SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '결제수단 선택',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              GridView.builder(
                shrinkWrap: true, // 자식 크기만큼
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final method = _options[index]['method'] as PaymentMethod;
                  final label = _options[index]['label'] as String;
                  final icon = _options[index]['icon'] as IconData;
                  final selected = _selectedMethod == method;

                  return _buildPaymentMethodTile(
                    label: label,
                    icon: icon,
                    color: Colors.green,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (_selectedMethod != method) {
                          _selectedMethod = method;
                          _limitAmntCtrl.text = formatCurrency(_realRmnAmnt);
                          _unLimitAmntCtrl.text = formatCurrency(_realRmnAmnt);
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              if (_selectedMethod == PaymentMethod.transfer) ...[
                Text(
                  '이체 금액',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: TextFormField(
                    controller: _unLimitAmntCtrl,
                    decoration: InputDecoration(border: InputBorder.none),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ),
              ] else if (_selectedMethod == PaymentMethod.card ||
                  _selectedMethod == PaymentMethod.vAccount) ...[
                Text(
                  '이체 금액',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: TextFormField(
                    controller: _limitAmntCtrl,
                    decoration: InputDecoration(border: InputBorder.none),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _clampLimitAmount(),
                    onEditingComplete: () {
                      _clampLimitAmount();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ],
              SizedBox(height: 20),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _onPay,
                  child: const Text('결제하기'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  /// 클래스 대신 메서드로 타일 위젯 구성
  Widget _buildPaymentMethodTile({
    required String label,
    required IconData icon,
    required bool selected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final primary = color ?? Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: selected ? primary : Colors.grey[800]),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? primary : Colors.black87,
                fontSize: 13,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Icon(Icons.check_circle, size: 18, color: primary),
            ],
          ],
        ),
      ),
    );
  }
}
