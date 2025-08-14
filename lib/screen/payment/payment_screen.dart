import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/observer/route_observer.dart';
import 'package:aetteullo_cust/screen/payment/payment_dtl_screen.dart';
import 'package:aetteullo_cust/screen/payment/submit_payment_screen.dart';
import 'package:aetteullo_cust/service/payment_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with RouteAware {
  final double _height = 90;
  late final PaymentService _paymentService;
  List<Map<String, dynamic>> _paymentList = [];
  double get _totRmnAmnt => _paymentList.fold(
    0.0,
    (acc, payment) => acc + (payment['rmnAmnt'] as double),
  );

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _loadPaymentList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _loadPaymentList();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadPaymentList() async {
    var rawList = await _paymentService.selectPaymentList();
    setState(() {
      _paymentList = rawList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MobileAppBar(title: '결제 관리'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  return ListView.builder(
                    padding: EdgeInsets.only(bottom: _height),
                    itemCount: _paymentList.length,
                    itemBuilder: (context, index) {
                      final payment = _paymentList[index];
                      return _buildDeliCard(item: payment);
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

  Widget _buildDeliCard({required Map<String, dynamic> item}) {
    final List<Map<String, dynamic>> items = (item['items'] as List)
        .cast<Map<String, dynamic>>();

    var title = '';
    if (items.length > 1) {
      title = '${items.first['itemNm']} 외 ${items.length - 1}';
    } else {
      title = items.first['itemNm'];
    }

    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentDtlScreen(item: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${formatCurrency(item['rmnAmnt'])}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('구매 금액:'),
                    const SizedBox(width: 10),
                    Text(
                      '${formatCurrency(item['purAmnt'])}원',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('결제 금액:'),
                    const SizedBox(width: 10),
                    Text(
                      '${formatCurrency(item['payAmnt'])}원',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      height: _height,
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
          const Icon(Icons.credit_card, color: Colors.green, size: 30),
          const SizedBox(width: 8),
          const Text(
            '미수금 결제',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubmitPaymentScreen(payments: _paymentList),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green, // 버튼 색상과 통일
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${formatCurrency(_totRmnAmnt)}원 결제',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
