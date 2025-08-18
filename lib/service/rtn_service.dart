import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class RtnService {
  /// GET /mobile/rtn?inDate=YYYY-MM-DD
  /// 반품 내역 리스트 조회
  Future<List<Map<String, dynamic>>> getRtnList({DateTime? rtnDate}) async {
    try {
      final response = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/rtn',
        queryParameters: {
          if (rtnDate != null)
            'rtnDate': DateFormat('yyyy-MM-dd').format(rtnDate),
        },
      );
      return response.data!
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException catch (e) {
      debugPrint('getRtnList Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getRtnList unexpected error: $e');
      rethrow;
    }
  }

  /// POST /mobile/rtn
  /// 요청 Body 예시:
  /// {
  ///   "item": { … },
  ///   "memo": "반품 사유 메모"
  /// }
  Future<void> submitRtn({
    required Map<String, dynamic> item,
    required String memo,
  }) async {
    try {
      await DioCookieClient.http.post(
        '/mobile/rtn',
        data: {'item': item, 'memo': memo},
      );
    } on DioException catch (e) {
      debugPrint('submitRtn Dio error: ${e.response?.statusCode} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('submitRtn unexpected error: $e');
      rethrow;
    }
  }
}
