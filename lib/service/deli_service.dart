import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliService {
  /// 배송 목록 조회
  /// [deliDate]가 주어지면 'yyyy-MM-dd' 포맷으로 query parameter 에 전달,
  /// 없으면 전체(서버에서는 7일 전부터 필터링)
  Future<List<Map<String, dynamic>>> getDeliList({DateTime? deliDate}) async {
    // queryParameters 맵 준비
    final queryParameters = <String, String>{};
    if (deliDate != null) {
      // ISO 포맷에서 날짜 부분만 잘라내기
      final formatted = DateFormat('yyyy-MM-dd').format(deliDate);
      queryParameters['deliDate'] = formatted; // ex: '2025-06-05'
    }

    try {
      final response = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/deli',
        queryParameters: queryParameters,
      );
      // response.data 가 List<dynamic> 이라고 가정하고,
      // 각 요소를 Map<String, dynamic> 으로 캐스트
      return response.data
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
    } on DioException catch (e) {
      debugPrint('getDeliList error: ${e.response?.statusCode} ${e.message}');
      rethrow;
    }
  }

  // 배송 확정 제출
  /// [item] 은 서버에 넘길 단일 Map 객체 (Java 쪽에서는 ConversionUtils.parseMap 로 처리)
  Future<void> submitFix({required Map<String, dynamic> item}) async {
    try {
      await DioCookieClient.http.post('/mobile/deli', data: {'item': item});
    } on DioException catch (e) {
      debugPrint('submitConfirm error: ${e.response?.statusCode} ${e.message}');
      rethrow;
    }
  }
}
