import 'package:flutter/material.dart';

class NoBasket extends StatelessWidget {
  const NoBasket({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙
        crossAxisAlignment: CrossAxisAlignment.center, // 수평 중앙
        children: [
          Image.asset('assets/icons/no_basket.png', fit: BoxFit.cover),
          const SizedBox(height: 10),
          const Text(
            '장바구니에 물품이 없습니다.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBDC0C4),
            ),
          ),
        ],
      ),
    );
  }
}
