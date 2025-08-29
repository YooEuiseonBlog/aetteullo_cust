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
import 'package:aetteullo_cust/screen/notice/notice_screen.dart';
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

// 권한 요청 상태를 추적하기 위한 전역 변수
bool _isPermissionRequesting = false;

Future<void> _initializeFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // 이미 권한 요청이 진행 중이면 대기
    if (_isPermissionRequesting) {
      print('권한 요청이 이미 진행 중입니다. 대기 중...');
      return;
    }

    _isPermissionRequesting = true;

    // 현재 권한 상태 확인
    NotificationSettings settings = await messaging.getNotificationSettings();
    print('현재 알림 권한 상태: ${settings.authorizationStatus}');

    // 권한이 결정되지 않은 경우에만 요청
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      print('알림 권한 요청 중...');
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      print('권한 요청 완료: ${settings.authorizationStatus}');
    } else {
      print('권한이 이미 설정되어 있음: ${settings.authorizationStatus}');
    }

    // FCM 토큰 가져오기 (선택사항)
    try {
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('FCM 토큰 가져오기 실패: $e');
    }
  } catch (e) {
    print('Firebase Messaging 초기화 오류: $e');
  } finally {
    _isPermissionRequesting = false;
  }
}

Future<void> main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // HTTP override
  HttpOverrides.global = MyHttpOverrides();

  try {
    // 1) Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase 초기화 완료');

    // 2) 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3) 안전한 권한 요청 (중복 방지)
    await _initializeFirebaseMessaging();

    // 4) 로컬 노티피케이션 초기화
    await NotificationService.instance.init();
    print('로컬 알림 서비스 초기화 완료');
  } catch (e) {
    print('초기화 오류 발생: $e');
    // 오류가 발생해도 앱은 계속 실행되도록 함
  }

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

class MainApp extends StatefulWidget {
  final Color aetteulloGreen = const Color(0xFF0DA45F);
  final Widget homePage;
  const MainApp({super.key, required this.homePage});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final Color aetteulloGreen = const Color(0xFF0DA45F);

  @override
  void initState() {
    super.initState();
    // 앱이 완전히 로드된 후 메시지 리스너 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMessageListeners();
    });
  }

  void _setupMessageListeners() {
    try {
      // 5) 포그라운드 메시지 수신 시 로컬 알림 띄우기
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        print('포그라운드 메시지 수신: ${msg.notification?.title}');
        final notif = msg.notification;
        if (notif != null) {
          NotificationService.instance.show(
            id: notif.hashCode,
            title: notif.title ?? '',
            body: notif.body ?? '',
            payload: msg.data['payload'],
          );
        }
      });

      // 6) 백그라운드에서 알림 클릭 시 처리
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
        print('백그라운드 알림 클릭: ${msg.notification?.title}');
        // TODO: 특정 화면으로 이동 로직 추가
        // Navigator.pushNamed(context, '/someRoute', arguments: msg.data);
      });

      // 7) 앱 종료 상태에서 알림 클릭 시 처리
      FirebaseMessaging.instance.getInitialMessage().then((msg) {
        if (msg != null) {
          print('앱 킬 상태 알림 클릭: ${msg.notification?.title}');
          // TODO: Navigator.pushNamed(context, '/someRoute', arguments: msg.data);
        }
      });

      print('메시지 리스너 설정 완료');
    } catch (e) {
      print('메시지 리스너 설정 오류: $e');
    }
  }

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
        home: widget.homePage, // 자동로그인 분기 반영
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/mypage': (_) => MyPageScreen(),
          '/payment': (_) => PaymentScreen(),
          '/orderhist': (_) => OrderHistScreen(),
          '/deli': (_) => DeliScreen(),
          '/notice': (_) => NoticeScreen(),
        },
      ),
    );
  }
}
