import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ChatService {
  Future<List<Map<String, dynamic>>> selectChatRoomList() async {
    try {
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/cust/chat',
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('selectChatRoomList ex: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> selectChatContent({
    required int chatRoomId,
  }) async {
    final resp = await DioCookieClient.http.get<List<dynamic>>(
      '/chat/$chatRoomId',
    );
    return (resp.data ?? []).cast<Map<String, dynamic>>();
  }
}
