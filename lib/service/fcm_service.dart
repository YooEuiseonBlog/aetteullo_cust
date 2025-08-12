import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final DioCookieClient _client;

  FcmService({DioCookieClient? dioClient})
    : _client = dioClient ?? DioCookieClient();

  void upsertFcmToken({
    required String deviceId,
    required String fcmToken,
  }) async {
    try {
      await _client.dio.post(
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
      await _client.dio.delete(
        '/fcm',
        data: <String, dynamic>{'deviceId': deviceId, 'appType': 'CLIENT'},
      );
    } on DioException catch (e) {
      debugPrint('dio ex: $e');
      rethrow;
    }
  }
}
