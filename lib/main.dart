import 'dart:io';
import 'package:aetteullo_cust/firebase_options.dart';
import 'package:aetteullo_cust/observer/route_observer.dart';
import 'package:aetteullo_cust/provider/app_state_provider.dart';
import 'package:aetteullo_cust/provider/com_code_provider.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/screen/deli/deli_screen.dart';
import 'package:aetteullo_cust/screen/home/home_screen.dart';
import 'package:aetteullo_cust/screen/login/login_screen.dart';
import 'package:aetteullo_cust/screen/mypage/my_page_screen.dart';
import 'package:aetteullo_cust/screen/orderhist/order_hist_screen.dart';
import 'package:aetteullo_cust/screen/payment/payment_screen.dart';
import 'package:aetteullo_cust/service/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 이 Isolate에서도 Firebase 초기화 필요
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('백그라운드 메시지: ${message.messageId}');
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // HTTP override
  HttpOverrides.global = MyHttpOverrides();

  // 1) Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3) iOS/Android 푸시 권한 요청
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 4) 로컬 노티피케이션 초기화
  await NotificationService.instance.init();

  // 5) 포그라운드 메시지 수신 시 로컬 알림 띄우기
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
    final notif = msg.notification;
    if (notif != null) {
      // ✅ 수정된 호출 (모두 named parameter)
      NotificationService.instance.show(
        id: notif.hashCode,
        title: notif.title ?? '',
        body: notif.body ?? '',
        payload: msg.data['payload'],
      );
    }
  });

  // 6) 앱 종료 상태에서 알림 클릭 시 처리
  FirebaseMessaging.instance.getInitialMessage().then((msg) {
    if (msg != null) {
      print('🛠 앱 킬 상태 알림 클릭: ${msg.notification?.title}');
      // TODO: Navigator.pushNamed(context, '/someRoute', arguments: msg.data);
    }
  });

  // 첫 진입 화면 설정 (로그인 또는 홈)
  Widget firstPage = const LoginScreen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ComCodeProvider()),
      ],
      child: MainApp(homePage: firstPage),
    ),
  );
}

class MainApp extends StatelessWidget {
  final Color aetteulloGreen = const Color(0xFF0DA45F);
  final Widget homePage;
  const MainApp({super.key, required this.homePage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 화면 터치 시 키보드 숨김 처리
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // 2. 지원할 로케일 지정
        supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        themeMode: ThemeMode.light, // 다크모드 무시
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: aetteulloGreen,
            primary: aetteulloGreen,
            // ... 기타 색들
          ),
          scaffoldBackgroundColor: Colors.white,
          // ----------------------------------------------------
          // 1) ExpansionTile 기본 Divider를 투명으로 (상단·하단 경계선)
          dividerColor: Colors.transparent,
          // 2) 터치 스플래시 / 하이라이트 이펙트 제거
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          // 3) ExpansionTile 배경(접힌/펼친) 모두 투명
          expansionTileTheme: const ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            // (필요하다면) 기본 tilePadding 과 childrenPadding 도 여기서 설정 가능
            // tilePadding: EdgeInsets.zero,
            // childrenPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          // ----------------------------------------------------
          // AppBar 전역 배경색을 흰색으로
          appBarTheme: const AppBarTheme(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          // 탭바 레이블 패딩 전역 제거
          tabBarTheme: const TabBarThemeData(labelPadding: EdgeInsets.zero),
        ),
        navigatorObservers: [routeObserver],
        home: homePage, // 자동로그인 분기 반영
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/mypage': (_) => MyPageScreen(),
          '/payment': (_) => PaymentScreen(),
          '/orderhist': (_) => OrderHistScreen(),
          '/deli': (_) => DeliScreen(),
        },
      ),
    );
  }
}
