// lib/service/sse_service.dart
import 'dart:async';
import 'package:aetteullo_cust/constant/constants.dart';
import 'package:launchdarkly_event_source_client/launchdarkly_event_source_client.dart';

class SSEService {
  SSEClient? _client;
  final String _apiURL = API_BASE_URL;
  final String token;

  SSEService({required this.token});

  /// 서버의 /sse/listen/{topic} 엔드포인트 구독
  Future<Stream<MessageEvent>> subscribe(String topic) async {
    final uri = Uri.parse('$_apiURL/sse/listen/$topic');

    _client = SSEClient(
      uri,
      {'init', 'trigger', 'message'}, // 서버에서 보낼 수 있는 이벤트명
      headers: {'Authorization': 'Bearer $token'},
    );

    // 그대로 MessageEvent 스트림을 돌려주고,
    // 필요하면 호출하는 쪽에서 evt.type, evt.data 사용
    return _client!.stream;
  }

  Future<void> dispose() async {
    await _client?.close();
    _client = null;
  }
}
