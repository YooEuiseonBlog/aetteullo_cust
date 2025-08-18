import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class PaymentVBankSuccessScreen extends StatelessWidget {
  final String bankNm;
  final String vactNo;
  final String holder;
  final String exprDt;
  final int amount;
  const PaymentVBankSuccessScreen({
    super.key,
    required this.bankNm,
    required this.vactNo,
    required this.holder,
    required this.amount,
    required this.exprDt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1) 재사용하는 앱바
      appBar: const MobileAppBar(
        title: Text(
          '',
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

      // 2) 성공 메시지
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                '예금주명: $holder',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                '가상계좌번호: $vactNo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '입금금액: ${formatCurrency(amount)}원',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '입금기한: $exprDt',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 40),

              // 3) 주요 액션 버튼: 주문 목록
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // OrderListScreen으로 교체하고 스택 정리
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 4) 재사용하는 하단 네비게이션 바
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
