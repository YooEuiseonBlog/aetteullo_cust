import 'package:flutter/material.dart';

class NoData extends StatelessWidget {
  const NoData({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙
        crossAxisAlignment: CrossAxisAlignment.center, // 수평 중앙
        children: [
          Image.asset('assets/icons/no_data_grey.png', fit: BoxFit.cover),
          const SizedBox(height: 10),
          const Text(
            '데이터가 없습니다.',
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
