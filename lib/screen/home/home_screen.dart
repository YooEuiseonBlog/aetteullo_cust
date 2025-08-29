import 'package:aetteullo_cust/constant/default_settings.dart';
import 'package:aetteullo_cust/function/device_utils.dart';
import 'package:aetteullo_cust/function/dialog_utils.dart';
import 'package:aetteullo_cust/observer/route_observer.dart';
import 'package:aetteullo_cust/screen/home/tabs/home_tab.dart';
import 'package:aetteullo_cust/screen/home/tabs/latest_order_tab.dart';
import 'package:aetteullo_cust/screen/home/tabs/like_tab.dart';
import 'package:aetteullo_cust/screen/home/tabs/promotion_tab.dart';
import 'package:aetteullo_cust/service/common_service.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:aetteullo_cust/service/fcm_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabController;
  final CommonService _commonService = CommonService();
  final FcmService _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    // 3) 사용자 정보와 장바구니 카운트 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 네비게이션 인덱스를 0으로 초기화
      _commonService.setNavIndex(context, 0);

      // 사용자 정보와 장바구니 카운트 초기화
      _commonService.fetchUser(context);
      _commonService.fetchBasketCnt(context);
      _commonService.getStat(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPopNext() {
    // 뒤로 와서 화면이 다시 보여질 때마다 0으로 초기화
    _commonService.setNavIndex(context, 0);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onExit() async {
    print('앱 종료 전 작업 수행');
    try {
      final deviceId = await getDeviceId();
      _fcmService.deleteFcmToken(deviceId: deviceId!);
      await DioCookieClient().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('앱 종료 전 API 호출 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 기본적으로 pop을 막음
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 이미 pop되었으면 리턴

        // 다이얼로그 표시
        await showExitConfirmDialog(
          context,
          onExit: _onExit,
          title: '로그아웃',
          content: '로그아웃을 하시겠습니까?',
          submitBtn: '로그아웃',
          onOff: false, // 중요: 이 값을 true로 설정해야 실제 앱 종료됨
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: MobileAppBar(
          isHome: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Material(
              color: Colors.white,
              child: TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                controller: _tabController,
                isScrollable: false,
                indicatorColor: Colors.green,
                indicatorWeight: 3.0,
                labelStyle: const TextStyle(fontSize: 14),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            HomeTab(),
            LatestOrderTab(),
            LikeTab(),
            PromotionTab(),
          ],
        ),
        bottomNavigationBar: const MobileBottomNavigationBar(),
      ),
    );
  }
}
