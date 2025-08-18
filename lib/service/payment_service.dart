import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PaymentService {
  Future<List<Map<String, dynamic>>> selectPaymentList() async {
    try {
      final rawList = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/payment',
      );
      return (rawList.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> selectPrePym() async {
    try {
      final response = await DioCookieClient.http.get<Map<String, dynamic>>(
        '/mobile/payment/prepym',
      );

      // 응답이 Map인지 안전하게 캐스팅
      return response.data ?? {};
    } on DioException catch (e) {
      debugPrint('error: $e');
      rethrow;
    }
  }
}
