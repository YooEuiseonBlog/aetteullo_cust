// constants.dart
const String BASE_URL = "https://192.168.0.13:8080";
// const String BASE_URL = "https://aetteullo.com";
const String API_BASE_URL = "$BASE_URL/api";
// WebSocket 연결용 (STOMP 없이 순수 WS 핸들러 /ws 엔드포인트)
// String WS_SCHEME = API_BASE_URL.replaceFirst('http', 'ws');
String WS_SCHEME = API_BASE_URL.replaceFirst('https', 'wss');
String WS_URL = "$WS_SCHEME/ws"; // ⇒ "ws://10.0.2.2:8080/ws"

const String AUTO_LOGIN = 'AUTO_LOGIN_CUST';
const String SESSION_TOKEN = 'SESSION_TOKEN_CUST';

// topics
const String CUST_PO_STAT_TOPIC = 'CUST_PO_STAT_TOPIC';
const String CUST_DELI_STAT_TOPIC = 'CUST_DELI_STAT_TOPIC';
