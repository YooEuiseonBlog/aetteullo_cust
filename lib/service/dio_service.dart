import 'package:aetteullo_cust/constant/constants.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [DioCookieClient]는 싱글톤 패턴으로 구현되어 있으며,
/// `Dio` 인스턴스와 쿠키를 관리하기 위한 [CookieJar]를 포함하고 있습니다.
///
/// - 서버와 통신 시, 동일한 쿠키를 자동으로 전달하여 세션을 유지하기 위함입니다.
/// - [BaseOptions]를 통해 기본 호스트 주소와 타임아웃을 설정합니다.
/// - [CookieManager]를 통해 Dio에서 쿠키를 자동으로 관리합니다.
class DioCookieClient {
  // 싱글톤 인스턴스
  static final DioCookieClient _instance = DioCookieClient._internal();

  // 내부 생성자
  DioCookieClient._internal() {
    // 쿠키를 저장할 [CookieJar] 생성
    cookieJar = CookieJar();

    // Dio 인스턴스 생성 후, 기본 옵션 설정
    dio = Dio(
      BaseOptions(
        // baseUrl: 'http://10.0.2.2:8080/api, // 기본 요청 경로
        baseUrl: API_BASE_URL, // 상수 사용
        connectTimeout: const Duration(seconds: 5), // 연결 타임아웃
        receiveTimeout: const Duration(seconds: 5), // 응답 수신 타임아웃
      ),
    );

    // 쿠키 매니저 인터셉터 등록
    // 이 인터셉터는 서버로부터 받은 쿠키를 [CookieJar]에 저장하고,
    // 요청 시 [CookieJar]에서 쿠키를 꺼내 전달합니다.
    dio.interceptors.add(CookieManager(cookieJar));
  }

  // 외부에서 접근할 수 있는 싱글톤 인스턴스 접근자
  factory DioCookieClient() => _instance;

  late final Dio dio;
  late final CookieJar cookieJar;

  Dio get client => dio;

  static Dio get http => _instance.dio;

  /// [login] 메서드는 사용자 이름과 비밀번호를 이용해 서버로 로그인 요청을 보냅니다.
  ///
  /// - 로그인 성공 시, [debugPrint]를 통해 상태 코드를 출력합니다.
  /// - 만약 [DioException]이 발생한다면 로그를 남기고, 예외를 상위로 다시 던집니다.
  Future<bool> login(String username, String password) async {
    try {
      // 이전에 저장된 쿠키 초기화(매번 클린한 상태로 로그인 시도)
      await cookieJar.deleteAll();

      await dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      // 로그인 후, baseUrl에 해당하는 쿠키 목록 확인
      final uri = Uri.parse(dio.options.baseUrl);
      final cookies = await cookieJar.loadForRequest(uri);
      if (cookies.isNotEmpty) {
        debugPrint('Received cookies: $cookies');
        return true;
      } else {
        debugPrint("No cookies received after login");
        return false;
      }
    } on DioException catch (e) {
      debugPrint('login error: $e');
      rethrow;
    }
  }

  /// 로그아웃: 서버에 POST /auth/logout 호출 → 쿠키, prefs 동시 정리
  Future<void> logout({String? token}) async {
    try {
      // 1) 서버 쪽 로그아웃 (쿠키 만료)
      await dio.post(
        '/auth/logout',
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      // 2) 클라이언트 쿠키 제거
      await cookieJar.deleteAll();

      // 3) 로컬 저장된 자동로그인 정보 및 토큰 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoLogin', false);
      await prefs.remove('sessionToken');

      debugPrint('logout: cleared cookies and local sessionToken');
    } on DioException catch (e) {
      debugPrint('logout error: $e');
      rethrow;
    }
  }

  Future<String?> getJwtToken() async {
    final uri = Uri.parse(DioCookieClient().dio.options.baseUrl);
    final cookies = await DioCookieClient().cookieJar.loadForRequest(uri);
    for (var cookie in cookies) {
      if (cookie.name == 'JWT_TOKEN') {
        return cookie.value;
      }
    }
    return null;
  }

  /// 서버의 POST /auth/token 엔드포인트에
  /// Authorization 헤더로 토큰을 보내고,
  /// 바디 { "valid": true/false }를 파싱해서 리턴합니다.
  Future<bool> verifyToken(String token) async {
    try {
      final response = await dio.post(
        '/auth/token',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // 응답 데이터가 Map 형태라고 가정
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('valid')) {
        return data['valid'] as bool;
      }
      // 형식이 예상과 다르면 false 처리
      return false;
    } on DioException catch (e) {
      // 네트워크 장애나 5xx 에러 등은 예외로 전달
      // 401 등은 바디에 valid:false 가 내려오므로 여기까지 안 옴
      debugPrint('verifyToken error: $e');
      rethrow;
    }
  }

  /// 4) 로컬에 저장된 JWT 토큰을 쿠키로 강제 세팅
  Future<void> setTokenToCookie(String token) async {
    // baseUrl 에 맞춰 Uri 생성
    final uri = Uri.parse(dio.options.baseUrl);
    // 서버에서 사용하는 쿠키 이름(JWT_TOKEN)과 동일해야 합니다
    await cookieJar.saveFromResponse(uri, [Cookie('JWT_TOKEN', token)]);
  }

  /// 5) Dio 인스턴스의 Authorization 헤더에 Bearer 토큰 설정
  void setTokenToAuthHeader(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
