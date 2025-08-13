import 'dart:async';

import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/service/chat_service.dart';
import 'package:aetteullo_cust/service/chat_socket_service.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final int chatRoomId;
  final String partnerCd;
  final String? partnerNm;
  final int partnerId;
  final String? userNm;
  final String? partnerUserNm;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.partnerCd,
    this.partnerNm,
    required this.partnerId,
    this.userNm,
    this.partnerUserNm,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  late ChatSocketService _socketService;

  StreamSubscription<dynamic>? _sub;

  /// 과거 + 실시간 누적 메시지
  final List<Map<String, dynamic>> _messages = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 1) REST로 과거 메시지를 불러옵니다.
    _chatService
        .selectChatContent(chatRoomId: widget.chatRoomId)
        .then((history) {
          setState(() {
            _messages.addAll(history.reversed);
          });
        })
        .catchError((e) {
          debugPrint('chatContent: $e');
        });

    // 2) WebSocket 서비스 초기화
    DioCookieClient().getJwtToken().then((token) {
      if (token == null) {
        throw Exception('토큰이 없습니다.');
      }

      _socketService = ChatSocketService(
        chatRoomId: widget.chatRoomId,
        token: token,
      );

      // 3) 서버 이벤트(enter/read/send 결과) 구독
      _sub = _socketService.eventStream.listen(
        (event) {
          setState(() {
            if (event is List) {
              // enter/read 업데이트 처리 (기존 로직)
              for (var u in event) {
                final idx = _messages.indexWhere(
                  (m) => m['chatContentId'] == u['chatContentId'],
                );

                if (idx != -1) {
                  _messages[idx]['readYn'] = u['readYn'];
                }
              }
            } else if (event is Map<String, dynamic>) {
              final msg = event;
              // 새 메세지 도착
              _messages.insert(0, msg);
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );

              // 만약 내가 보낸 메세지가 아니면 자동으로 읽음 처리 요청
              final int myId = context.read<UserProvider>().user.userId!;
              final int userId = msg['userId'] as int;
              final int chatContentId = msg['chatContentId'] as int;

              if (myId != userId) {
                // 서버에 read 액션 보내기
                _socketService.markRead(chatContentId: chatContentId);
              }
            }
          });
        },
        onError: (e) {
          // 에러 처리
          debugPrint('on Error: $e');
        },
      );

      _socketService.enter();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _socketService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final text = _messageController.text.trim();
      if (text.isEmpty) return;

      _socketService.sendMessage(content: text);
      _messageController.clear();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<UserProvider>().user.userId;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MobileAppBar(
        title: widget.partnerUserNm,
        showBasket: false,
        showNotification: false,
        showSearch: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, idx) {
                        final msg = _messages[idx];
                        final content = msg['content'] as String?;
                        final regDate = msg['regDate'] as String? ?? '';
                        final isMe = myId == msg['userId'] as int?;
                        final readYn = msg['readYn'] as String? ?? 'N';

                        return _buildBubble(
                          content ?? '내용 없음',
                          isMe,
                          regDate,
                          readYn: readYn,
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(color: Colors.green),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) => _onSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onSend,
                    child: const Text(
                      '전송',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  Widget _buildBubble(String text, bool isMe, String date, {String? readYn}) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 250),
              decoration: BoxDecoration(
                color: isMe ? Colors.green[400] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (isMe && readYn != null)
                  Text(
                    readYn == 'Y' ? '읽음' : '안읽음',
                    style: TextStyle(
                      fontSize: 10,
                      color: readYn == 'Y' ? Colors.blue : Colors.grey,
                    ),
                  ),
                const SizedBox(width: 5),
                Text(
                  formatYyyyMMdd(date, '-'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
