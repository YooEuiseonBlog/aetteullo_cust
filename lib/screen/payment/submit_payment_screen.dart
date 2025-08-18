import 'package:aetteullo_cust/constant/constants.dart';
import 'package:aetteullo_cust/formatter/formatter.dart';
import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/screen/payment/payment_form_web_view.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
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
  final TextEditingController _amntCtrl = TextEditingController();

  String get _partnerCd => _payments.first['partnerCd'];
  double get _totRmnAmnt => _payments.fold<double>(
    0.0,
    (acc, p) => acc + ((p['rmnAmnt'] as num?)?.toDouble() ?? 0.0),
  );

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

  @override
  void initState() {
    super.initState();
    _payments = [...widget.payments.cast<Map<String, dynamic>>()];
    _amntCtrl.text = formatCurrency(_totRmnAmnt);
  }

  @override
  void dispose() {
    _amntCtrl.dispose();
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

      final amt = (_selectedMethod == PaymentMethod.transfer)
          ? int.tryParse(_amntCtrl.text.replaceAll(',', '').trim()) ?? 0
          : _totRmnAmnt.toInt();

      if (amt <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('결제 금액이 없습니다.')));
        return;
      }

      final path = _pathOf(_selectedMethod!);
      final user = context.read<UserProvider>().user;

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('총 결제금액', style: TextStyle(fontSize: 16)),
                Text(
                  '${formatCurrency(_totRmnAmnt)}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
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
                    setState(() => _selectedMethod = method);
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
                  controller: _amntCtrl,
                  decoration: InputDecoration(border: InputBorder.none),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsFormatter(),
                  ],
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 20),
            ],
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
                fontWeight: FontWeight.w600,
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
