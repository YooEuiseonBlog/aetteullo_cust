import 'package:aetteullo_cust/provider/app_state_provider.dart';
import 'package:aetteullo_cust/provider/com_code_provider.dart';
import 'package:aetteullo_cust/provider/model/user.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 자바 HomeController의 '/api/v1/mobile/home/orderHistList' 엔드포인트와 통신하는 API 서비스 클래스
class CommonService {
  Future<int> _fetchBkCnt() async {
    final response = await DioCookieClient.http.get('/mobile/basket/count');
    if (response.statusCode == 200) {
      return (response.data as Map<String, dynamic>)['count'] as int;
    }
    throw Exception(
      'Failed to fetch basket count: HTTP ${response.statusCode}',
    );
  }

  Future<User> _fetchUser() async {
    try {
      final response = await DioCookieClient.http.get('/mobile/user');
      return User.fromJson(response.data);
    } catch (e) {
      debugPrint('_fetchUser error: $e');
      rethrow;
    }
  }

  Future<int> _fetchNotificationCnt() async {
    final resp = await DioCookieClient.http.get(
      '/mobile/home/getNotificationCnt',
    );
    if (resp.statusCode == 200) {
      return (resp.data as Map<String, dynamic>)['notificationCnt'] as int;
    }
    throw Exception(
      'Failed to fetch notification count: HTTP ${resp.statusCode}',
    );
  }

  // ──────────────── Basket Count ────────────────

  /// Provider에서 basketCount를 watch로 구독하여 반환 (실패 시 0)
  int getBkCnt(BuildContext context) {
    try {
      return context.watch<AppStateProvider>().basketCount;
    } catch (e) {
      debugPrint('[CommonService.getBkCnt] Error: $e');
      return 0;
    }
  }

  /// 서버에서 basketCount를 가져와 Provider에 저장
  Future<void> fetchBasketCnt(
    BuildContext context, {
    bool showErrorMsg = true,
  }) async {
    try {
      final bkCnt = await _fetchBkCnt();
      if (context.mounted) {
        context.read<AppStateProvider>().setBasketCount(bkCnt);
      }
    } catch (e) {
      debugPrint('[CommonService.updateBasketCount] $e');
      if (showErrorMsg && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('장바구니 수 업데이트 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        rethrow;
      }
    }
  }

  // ──────────────── User Data ────────────────

  /// 서버에서 최신 사용자 정보 가져와 Provider에 반영
  Future<void> fetchUser(
    BuildContext context, {
    bool showErrorMsg = true,
  }) async {
    try {
      final user = await _fetchUser();
      if (context.mounted) {
        context.read<UserProvider>().updateUser(user);
      }
    } catch (e) {
      debugPrint('[CommonService.updateAndSetCurrentUser] $e');
      if (showErrorMsg && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 정보 업데이트 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        rethrow;
      }
    }
  }

  // ──────────────── Navigation Index ────────────────

  /// Provider에 navIndex를 저장
  void setNavIndex(BuildContext context, int index) {
    try {
      context.read<AppStateProvider>().setNavIndex(index);
    } catch (e) {
      debugPrint('[CommonService.setNavIndex] Error: $e');
    }
  }

  /// 서버에서 notificationCnt를 받아 Provider에 저장
  Future<void> fetchNotificationCnt(
    BuildContext context, {
    bool showErrorMsg = true,
  }) async {
    try {
      final cnt = await _fetchNotificationCnt();
      if (context.mounted) {
        context.read<AppStateProvider>().setNotificationCount(cnt);
      }
    } catch (e) {
      debugPrint('[CommonService.updateNotificationCount] $e');
      if (showErrorMsg && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 수 업데이트 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        rethrow;
      }
    }
  }

  /// GET /mobile/comm/bank
  /// 은행 코드 및 명칭 리스트 조회
  Future<List<Map<String, dynamic>>> getBankInfo() async {
    try {
      final response = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/comm/bank',
      );
      return response.data!
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException catch (e) {
      debugPrint('getBankInfo Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getBankInfo unexpected error: $e');
      rethrow;
    }
  }

  /// GET /mobile/comm/depositType
  /// 예치금 구분 리스트 조회
  Future<List<Map<String, dynamic>>> getDepositType() async {
    try {
      final response = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/comm/depositType',
      );
      return response.data!
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException catch (e) {
      debugPrint('getDepositType Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getDepositType unexpected error: $e');
      rethrow;
    }
  }

  /// GET /mobile/comm/payType
  /// 예치금 구분 리스트 조회
  Future<List<Map<String, dynamic>>> getPayType() async {
    try {
      final response = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/comm/payType',
      );
      return response.data!
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException catch (e) {
      debugPrint('getDepositType Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getDepositType unexpected error: $e');
      rethrow;
    }
  }

  /// GET /mobile/comm/stat
  /// 통계 정보를 키별로 리스트 형태로 반환
  Future<Map<String, List<Map<String, dynamic>>>> _getStat() async {
    try {
      final response = await DioCookieClient.http.get<Map<String, dynamic>>(
        '/mobile/comm/stat',
      );
      final data = response.data!;

      // value가 List<dynamic>이므로 cast 메서드로 바로 Map<String, dynamic> 리스트로 변환
      return data.map<String, List<Map<String, dynamic>>>(
        (key, value) =>
            MapEntry(key, (value as List).cast<Map<String, dynamic>>()),
      );
    } on DioException catch (e) {
      debugPrint('getStat Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getStat unexpected error: $e');
      rethrow;
    }
  }

  Future<void> getStat(BuildContext context) async {
    final comCodesMap = await _getStat();
    if (context.mounted) {
      context.read<ComCodeProvider>().setComCodes(comCodesMap);
    }
  }
}
