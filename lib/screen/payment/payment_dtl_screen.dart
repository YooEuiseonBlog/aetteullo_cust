import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/etc/info_field.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:aetteullo_cust/widget/section/expandable_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PaymentDtlScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const PaymentDtlScreen({super.key, required this.item});

  @override
  State<PaymentDtlScreen> createState() => _PaymentDtlScreenState();
}

class _PaymentDtlScreenState extends State<PaymentDtlScreen> {
  late final Map<String, dynamic> _item;
  String get _title {
    final items = (_item['items'] as List).cast<Map<String, dynamic>>();
    final cnt = items.length - 1;
    final firstItemNm = items.first['itemNm'];

    return cnt > 1 ? '$firstItemNm 외 $cnt 건' : '$firstItemNm';
  }

  @override
  void initState() {
    super.initState();
    _item = Map.from(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MobileAppBar(title: '결제 정보'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            ExpandableSection(
              title: '결제 정보',
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              onExpansionChanged: (value) {},
              children: [
                InfoField(
                  label: '배송명',
                  value: Text(
                    _title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                InfoField(
                  label: '결제일',
                  value: formatYyyyMMdd(_item['purDate'] as String, '-'),
                ),
                InfoField(
                  label: '구매 금액',
                  value: Text(
                    '${formatCurrency(_item['purAmnt'])}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                InfoField(
                  label: '결제 금액',
                  value: Text(
                    '${formatCurrency(_item['payAmnt'])}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                InfoField(
                  removeUnderline: true,
                  label: const Text(
                    '미결제 금액',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.blue,
                    ),
                  ),
                  value: Text(
                    '${formatCurrency(_item['purAmnt'])}원',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ExpandableSection(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              onExpansionChanged: (value) {},
              isExpanded: true,
              title: '품목',
              children: [
                ListView.builder(
                  itemCount: (_item['items'] as List).length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = (_item['items'] as List<dynamic>)
                        .cast<Map<String, dynamic>>()[index];
                    return _buildPaymentCard(item: item);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  Widget _buildPaymentCard({required Map<String, dynamic> item}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item['itemNm']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: CachedNetworkImage(imageUrl: item['image1'])),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '업체',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${item['mnfct']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '단가',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${formatCurrency(item['price'])}원',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '수량',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${(item['qty'] as double).toInt()}${item['unitNm']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '금액',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${((item['qty'] * item['price']) as double).toInt()}원',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
