import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  void upsertFcmToken({
    required String deviceId,
    required String fcmToken,
  }) async {
    try {
      await DioCookieClient.http.post(
        '/fcm',
        data: <String, dynamic>{
          'deviceId': deviceId,
          'fcmToken': fcmToken,
          'appType': 'CLIENT',
        },
      );
    } on DioException catch (e) {
      debugPrint('dio ex: $e');
      rethrow;
    }
  }

  void deleteFcmToken({required String deviceId}) async {
    try {
      await DioCookieClient.http.delete(
        '/fcm',
        data: <String, dynamic>{'deviceId': deviceId, 'appType': 'CLIENT'},
      );
    } on DioException catch (e) {
      debugPrint('dio ex: $e');
      rethrow;
    }
  }
}
