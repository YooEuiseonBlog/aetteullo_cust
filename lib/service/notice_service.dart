import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class NoticeService {
  Future<List<Map<String, dynamic>>> selectNoticeList() async {
    try {
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/notice',
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('err: $e');
      rethrow;
    }
  }
}
