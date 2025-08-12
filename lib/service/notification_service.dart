import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 앱 전역에서 쓰는 채널 정보
class NotificationChannel {
  static const AndroidNotificationChannel highImportance =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Nofitications',
    description: '이 채널은 중요한 알림에 사용합니다.',
    importance: Importance.high,
  );
}

class NotificationService {
  // ① private 생성자 + 싱글톤 인스턴스
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ② 로컬 노티 플러그인 인스턴스
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 초기화: 채널 생성, iOS 권한 요청, 플러그인 초기화
  Future<void> init() async {
    // Android 채널 생성
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(NotificationChannel.highImportance);

    // iOS/macOS 로컬 노티 권한 요청을 DarwinInitializationSettings로 처리
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true, // 권한 요청 팝업 띄우기
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 전체 초기화 옵션(Android + iOS/macOS)
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    // 플러그인 초기화 (알림 클릭 콜백)
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          // TODO: 알림 클릭 시 네비게이션 등 처리
          print('🔔 알림 클릭 payload: $payload');
        }
      },
    );
  }

  /// 실제 노티를 띄울 때 호출할 메서드 (클래스 레벨로 분리)
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannel.highImportance.id,
          NotificationChannel.highImportance.name,
          channelDescription: NotificationChannel.highImportance.description,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
