import 'package:aetteullo_cust/provider/app_state_provider.dart';
import 'package:aetteullo_cust/screen/home/home_screen.dart';
import 'package:aetteullo_cust/service/common_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileBottomNavigationBar extends StatelessWidget {
  const MobileBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CommonService();
    final currentIndex = context.watch<AppStateProvider>().navIndex;

    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: currentIndex,
      onTap: (index) {
        // 인덱스가 같으면 아무 동작도 수행하지 않음
        if (index == currentIndex) return;

        // 다른 인덱스면 Provider에 저장
        service.setNavIndex(context, index);

        // 화면 전환
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(
              context,
              HomeScreen.routeName,
              (route) => false,
            );
            break;
          case 1:
            Navigator.pushNamed(context, "/orderHist");
            break;
          case 2:
            Navigator.pushNamed(context, "/deli");
            break;
          case 3:
            Navigator.pushNamed(context, "/payment");
            break;
          case 4:
            Navigator.pushNamed(context, "/mypage");
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: '주문내역',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: '배송 관리',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment_outlined),
          activeIcon: Icon(Icons.payment),
          label: '결제 관리',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2_outlined),
          activeIcon: Icon(Icons.person_2),
          label: '내 정보',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0CC377),
      unselectedItemColor: Colors.grey,
    );
  }
}
