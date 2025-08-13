// lib/services/chat_socket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aetteullo_cust/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

/// 순수 WebSocket 핸들러 프로토콜 대응
class ChatSocketService {
  final int chatRoomId;
  late final IOWebSocketChannel _channel;
  final _controller = StreamController<dynamic>.broadcast();

  /// 서버에서 브로드캐스트한 이벤트(Map or List<Map>) 스트림
  Stream<dynamic> get eventStream => _controller.stream;

  ChatSocketService({required this.chatRoomId, required String token}) {
    // ws://10.0.2.2:8080/api/ws/{chatRoomId}
    _channel = IOWebSocketChannel.connect(
      Uri.parse('$WS_URL/$chatRoomId'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    _channel.stream.listen(
      (raw) {
        try {
          final decoded = json.decode(raw as String);
          _controller.add(decoded);
        } catch (e) {
          debugPrint('json decode error: $e');
        }
      },
      onError: (e) {
        _controller.addError(e);
      },
      onDone: () => _controller.close(),
    );
  }

  /// 방 입장 요청: 서버에서 readYn 처리 후 업데이트를 브로드캐스트
  void enter() {
    final payload = {'action': 'enter'};
    _channel.sink.add(json.encode(payload));
  }

  /// 개별 메시지 읽음 처리 요청
  void markRead({required int chatContentId}) {
    final payload = {'action': 'read', 'chatContentId': chatContentId};
    _channel.sink.add(json.encode(payload));
  }

  /// 새 메시지 전송 요청
  void sendMessage({required String content}) {
    final payload = {'action': 'send', 'content': content};
    _channel.sink.add(json.encode(payload));
  }

  /// 정리
  void dispose() {
    _channel.sink.close();
    _controller.close();
  }
}
