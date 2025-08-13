import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class UserService {
  /// GET /mobile/user
  /// 사용자 정보 조회
  Future<Map<String, dynamic>> getUser() async {
    try {
      final response = await DioCookieClient.http.get<Map<String, dynamic>>(
        '/mobile/user',
      );
      return response.data!;
    } on DioException catch (e) {
      debugPrint('getCustUser Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getCustUser unexpected error: $e');
      rethrow;
    }
  }

  /// POST /mobile/user
  /// 사용자 정보 업데이트
  Future<void> updateUser({
    String? userNm,
    required String phone,
    required String email,
    required String passwd,
  }) async {
    try {
      await DioCookieClient.http.post(
        '/mobile/user',
        data: {
          if (userNm != null && userNm.isNotEmpty) 'userNm': userNm,
          'phone': phone,
          'email': email,
          'passwd': passwd,
        },
      );
    } on DioException catch (e) {
      debugPrint('updateCustUser Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('updateCustUser unexpected error: $e');
      rethrow;
    }
  }

  /// POST /mobile/user/validate/pwd
  /// 비밀번호 검증
  Future<Map<String, dynamic>> validatePasswd({required String passwd}) async {
    try {
      final response = await DioCookieClient.http.post<Map<String, dynamic>>(
        '/mobile/user/validate/pwd',
        data: {'passwd': passwd},
      );
      return response.data!;
    } on DioException catch (e) {
      debugPrint('validatePasswd Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('validatePasswd unexpected error: $e');
      rethrow;
    }
  }

  /// GET /mobile/user/info/acct
  /// 계좌 정보 조회 (저장된 계좌가 없으면 null 반환)
  Future<Map<String, dynamic>?> getAccountInfo() async {
    try {
      final response = await DioCookieClient.http.get<Map<String, dynamic>>(
        '/mobile/user/info/acct',
      );
      // 204 No Content 처리 혹은 body가 비어있으면 null
      if (response.statusCode == 204 ||
          response.data == null ||
          response.data!.isEmpty) {
        return null;
      }
      return response.data;
    } on DioException catch (e) {
      debugPrint('getAccountInfo Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getAccountInfo unexpected error: $e');
      rethrow;
    }
  }

  /// POST /mobile/user/info/acct
  /// 계좌 정보 저장/수정
  Future<void> saveAccountInfo({
    required String bankDiv,
    required String bankAcctNo,
    required String acctNm,
  }) async {
    try {
      await DioCookieClient.http.post(
        '/mobile/user/info/acct',
        data: {'bankDiv': bankDiv, 'bankAcctNo': bankAcctNo, 'acctNm': acctNm},
      );
    } on DioException catch (e) {
      debugPrint('saveAccountInfo Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('saveAccountInfo unexpected error: $e');
      rethrow;
    }
  }

  /// GET /mobile/user/info/deposit
  /// 예치금 정보 조회 (등록된 데이터가 없으면 null 반환)
  Future<Map<String, dynamic>?> getCustDeposit() async {
    try {
      final response = await DioCookieClient.http.get<Map<String, dynamic>>(
        '/mobile/user/info/deposit',
      );
      if (response.statusCode == 204 ||
          response.data == null ||
          response.data!.isEmpty) {
        return null;
      }
      return response.data;
    } on DioException catch (e) {
      debugPrint('getCustDeposit Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getCustDeposit unexpected error: $e');
      rethrow;
    }
  }

  /// GET /mobile/user/info/limit
  /// 신용 한도 정보 조회 (등록된 데이터가 없으면 null 반환)
  Future<Map<String, dynamic>?> getIndustLimit() async {
    try {
      final response = await DioCookieClient.http.get<Map<String, dynamic>>(
        '/mobile/user/info/limit',
      );
      if (response.statusCode == 204 ||
          response.data == null ||
          response.data!.isEmpty) {
        return null;
      }
      return response.data;
    } on DioException catch (e) {
      debugPrint('getIndustLimit Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getIndustLimit unexpected error: $e');
      rethrow;
    }
  }

  /// POST /mobile/user/info/limit
  /// 신용 한도 설정
  Future<void> setIndustLimit({
    required String creditLimitAmnt,
    required String creditLimitApp,
  }) async {
    try {
      await DioCookieClient.http.post(
        '/mobile/user/info/limit',
        data: {
          'creditLimitAmnt': creditLimitAmnt,
          'creditLimitApp': creditLimitApp,
        },
      );
    } on DioException catch (e) {
      debugPrint('setIndustLimit Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('setIndustLimit unexpected error: $e');
      rethrow;
    }
  }
}
