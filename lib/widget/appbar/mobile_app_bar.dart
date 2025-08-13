import 'package:aetteullo_cust/provider/app_state_provider.dart';
import 'package:aetteullo_cust/screen/basket/basket_screen.dart';
import 'package:aetteullo_cust/screen/home/home_screen.dart';
import 'package:aetteullo_cust/screen/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic title;
  final bool showSearch;
  final bool showNotification;
  final bool showBasket;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool isHome;

  const MobileAppBar({
    super.key,
    this.bottom,
    this.title,
    this.showSearch = true,
    this.showBasket = true,
    this.showNotification = true,
    this.leading,
    this.isHome = false,
  });

  Widget get _titleWidget {
    if (title != null) {
      if (title is String) {
        return Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );
      } else {
        return title;
      }
    } else {
      return Image.asset(
        'assets/icons/app_logo_alpha2.png',
        width: 100, // 원하시는 크기로 조정
        fit: BoxFit.contain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // CommonService.getLocalBasketCount을 사용
    final basketCount = showBasket
        ? context.watch<AppStateProvider>().basketCount
        : 0;

    final notificationCount = showNotification
        ? context.watch<AppStateProvider>().notificationCount
        : 0;

    return AppBar(
      title: GestureDetector(
        onTap: title == null
            ? () {
                if (!isHome) {
                  // 스택을 모두 지우고 홈으로 이동
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    HomeScreen.routeName,
                    (route) => false,
                  );
                }
              }
            : null,
        child: _titleWidget,
      ),
      leading: leading,
      actions: [
        if (showSearch)
          // ignore: prefer_const_constructors
          ActionButton(
            icon: Icons.search,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        if (showNotification)
          // ignore: prefer_const_constructors
          ActionButton(
            icon: Icons.notifications_none,
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const NotificationScreen()),
              // );
            },
            badgeCnt: notificationCount,
          ),
        if (showBasket)
          // ignore: prefer_const_constructors
          ActionButton(
            icon: Icons.shopping_cart_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BasketScreen()),
              );
            },
            badgeCnt: basketCount,
          ),
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCnt;

  // const 제거, super(key: key) 추가
  const ActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badgeCnt = 0,
  });

  @override
  Widget build(BuildContext context) {
    final touchArea = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(child: Icon(icon, color: Colors.black87, size: 24)),
      ),
    );

    if (badgeCnt > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            touchArea,
            Positioned(
              right: 4,
              top: 6,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: Text(
                  badgeCnt.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: touchArea,
    );
  }
}
