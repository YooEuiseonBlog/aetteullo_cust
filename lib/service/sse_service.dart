// lib/service/sse_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:aetteullo_cust/constant/constants.dart';
import 'package:featurehub_sse_client/featurehub_sse_client.dart';

// 서버에서 오는 SSE 이벤트를 이름(event)과 데이터(data)로 함께 전달하는 모델
class SseEvent {
  final String event;
  final dynamic data;
  SseEvent(this.event, this.data);
}

/// EventSource 기반 SSE 구독 서비스 (featurehub_sse_client)
class SSEService {
  // ex) '${API_BASE_URL}/sse'
  EventSource? _es; // 내부 EventSource 인스턴스
  final String _apiURL = API_BASE_URL; // 기존 상수 사용
  final String token;

  SSEService({required this.token});

  /// topic에 맞춰 SSE 연결을 열고, SseEvent 스트림을 리턴합니다.
  Future<Stream<SseEvent>> subscribe(String topic) async {
    final url = '$_apiURL/sse/listen/$topic';

    // featurehub_sse_client: 문자열 URL 사용 권장
    _es = await EventSource.connect(
      url,
      headers: {
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $token',
      },
      // 마지막 리스너가 제거되면 연결을 닫을지 여부 (필요 시)
      closeOnLastListener: true,
    );

    // EventSource는 Stream<Event>를 구현 → 그대로 map
    return _es!.map((e) {
      dynamic payload = e.data;
      try {
        if (e.data is String) {
          final s = (e.data as String).trim();
          if (s.isNotEmpty && (s.startsWith('{') || s.startsWith('['))) {
            payload = jsonDecode(s);
          }
        }
      } catch (_) {
        // 파싱 실패 시 원문 유지
        payload = e.data;
      }
      // e.event 가 null일 수 있으므로 기본값 'message'
      return SseEvent(e.event ?? 'message', payload);
    });
  }
}
