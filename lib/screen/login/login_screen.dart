import 'package:aetteullo_cust/constant/constants.dart';
import 'package:aetteullo_cust/function/device_utils.dart';
import 'package:aetteullo_cust/function/dialog_utils.dart';
import 'package:aetteullo_cust/screen/home/home_screen.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:aetteullo_cust/service/fcm_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAutoLogin = false; // 자동 로그인 체크박스 상태
  bool isPasswordObscured = true; // 비밀번호 감추기 상태
  final FcmService _fcmService = FcmService();
  final FirebaseMessaging _firebaseMessagingInstance =
      FirebaseMessaging.instance;
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwdController = TextEditingController();

  bool _isLogining = false; // 로그인 요청 중 상태

  @override
  void initState() {
    super.initState();
    // idController.text = 'nolbu1';
    // idController.text = 'yoo_eui_seon';
    _loadAutoLoginPref();
    // idController.text = 'error_open';
    // idController.text = 'pm-dis1';
    idController.text = 'gr-cus1';
    pwdController.text = '7877';
  }

  Future<void> _loadAutoLoginPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAutoLogin = prefs.getBool('autoLogin') ?? false;
    });
  }

  void _onLoginPressed() async {
    if (_isLogining) return;
    setState(() => _isLogining = true);

    final id = idController.text.trim();
    final pw = pwdController.text.trim();
    if (id.isEmpty || pw.isEmpty) {
      _showErrorDialog('아이디와 비밀번호를 모두 입력해주세요.');
      setState(() => _isLogining = false);
      return;
    }

    try {
      // 1) 로그인 (쿠키 기반 세션 유지)
      final loginSuccess = await DioCookieClient().login(id, pw);
      if (!loginSuccess) {
        _showErrorDialog('아이디 또는 비밀번호가 잘못되었습니다.');
        return;
      }

      // ↓ 자동로그인 플래그와 (옵션) 세션토큰 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AUTO_LOGIN, isAutoLogin);

      if (isAutoLogin) {
        // 예시: 서버에서 받은 JWT나 세션토큰이 있다면 저장
        final sessionToken = await DioCookieClient().getJwtToken();
        if (sessionToken != null) {
          await prefs.setString(SESSION_TOKEN, sessionToken);
        }
      }

      // (1) FCM 토큰과 디바이스 ID 가져오기
      final did = await getDeviceId();
      final fcmToken = await _firebaseMessagingInstance.getToken();

      // (2) 서버에 바인딩 요청
      if (did != null && fcmToken != null) {
        try {
          _fcmService.upsertFcmToken(deviceId: did, fcmToken: fcmToken);
          print('✅ FCM 토큰 바인딩 완료: $fcmToken');
        } catch (e) {
          print('✅ FCM 토큰 바인딩 완료: $fcmToken');
        }
      }

      // (3) 토큰 갱신 시에도 자동으로 바인딩
      _firebaseMessagingInstance.onTokenRefresh.listen((newToken) async {
        final cdid = await getDeviceId();
        if (cdid != null) {
          try {
            _fcmService.upsertFcmToken(deviceId: cdid, fcmToken: newToken);
            print('🔄 FCM 토큰 갱신 바인딩 완료: $newToken');
          } catch (e) {
            print('❌ FCM 토큰 갱신 바인딩 실패: $e');
          }
        }
      });

      // 5) 홈 화면으로 이동
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on DioException catch (e) {
      debugPrint('$e');
      // 로그인 자체 실패
      _showErrorDialog('아이디 또는 비밀번호가 잘못되었습니다.');
    } finally {
      setState(() => _isLogining = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 앱 종료 전 해야 할 작업을 여기에 작성합니다.
  Future<void> _onExit() async {
    // 예: 로그 기록, 리소스 해제, 기타 종료 전 작업
    print('앱 종료 전 작업 수행');
    try {
      final deviceId = await getDeviceId();
      _fcmService.deleteFcmToken(deviceId: deviceId!);
    } on Exception catch (e) {
      // API 호출 실패하더라도 예외를 무시하고 종료합니다.
      print('앱 종료 전 API 호출 실패: $e');
    }
  }

  @override
  void dispose() {
    idController.dispose();
    pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 메인 컬러 설정
    const Color mainColor = Color(0xFF0cc377);

    return WillPopScope(
      onWillPop: () =>
          showExitConfirmDialog(context, onExit: _onExit, onOff: true),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          child: Column(
            children: [
              // 상단 로고 및 텍스트
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/icons/app_logo_alpha3.png',
                          width: 180, // 원하시는 크기로 조정
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 하단 입력 폼 및 버튼
              Flexible(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 아이디 입력
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '아이디',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: UnderlineInputBorder(),
                        ),
                        controller: idController,
                      ),
                      const SizedBox(height: 16),
                      // 비밀번호 입력
                      TextField(
                        controller: pwdController,
                        obscureText: isPasswordObscured,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: const UnderlineInputBorder(),
                          suffix: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => pwdController.clear(),
                              ),
                              IconButton(
                                icon: Icon(
                                  isPasswordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () =>
                                      isPasswordObscured = !isPasswordObscured,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 자동로그인 체크박스
                      Row(
                        children: [
                          Checkbox(
                            value: isAutoLogin,
                            onChanged: (value) {
                              setState(() {
                                isAutoLogin = value ?? false;
                              });
                            },
                            activeColor: mainColor,
                          ),
                          const Text('자동로그인', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 로그인 버튼
                      ElevatedButton(
                        onPressed: _onLoginPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: _isLogining
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                '로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      // 하단 링크
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
