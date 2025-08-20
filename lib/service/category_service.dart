import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CategoryService {
  Future<Map<String, List<Map<String, dynamic>>>> fetchCategory() async {
    try {
      final response = await DioCookieClient.http.get<Map<String, dynamic>>(
        "/mobile/category",
      );
      final ctgryMap = response.data ?? <String, dynamic>{};
      // 각 레벨별로 List<Map<String, dynamic>> 으로 변환
      final Map<String, List<Map<String, dynamic>>> result = {};
      for (final level in ['main', 'mid', 'sub']) {
        final rawList = ctgryMap[level];
        if (rawList is List) {
          result[level] = rawList.whereType<Map<String, dynamic>>().toList();
        } else {
          result[level] = <Map<String, dynamic>>[];
        }
      }
      return result;
    } on DioException catch (e) {
      debugPrint('getCategory Dio error: ${e.message}');
      rethrow;
    } on FormatException catch (e) {
      debugPrint('getCategory parsing error: ${e.message}');
      throw Exception('Data parsing failed: ${e.message}');
    }
  }
}
