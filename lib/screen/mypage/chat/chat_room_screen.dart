import 'package:aetteullo_cust/screen/mypage/chat/chat_screen.dart';
import 'package:aetteullo_cust/service/chat_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _chatService = ChatService();
  late Future<List<Map<String, dynamic>>> _chatRooms;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  void _loadChatRooms() {
    setState(() {
      _chatRooms = _chatService.selectChatRoomList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MobileAppBar(title: '채팅'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FutureBuilder(
              future: _chatRooms,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // 로딩 중일 때
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // 에러 났을 때
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }

                final chatRoomList = snapshot.data;
                if (chatRoomList == null || chatRoomList.isEmpty) {
                  // 데이터가 비어 있을 때
                  return const Center(child: Text('참여 중인 채팅방이 없습니다.'));
                }
                // 정상적으로 데이터가 있을 때
                return ListView.builder(
                  itemCount: chatRoomList.length,
                  itemBuilder: (context, index) {
                    final chatRoom = chatRoomList[index];
                    final chatRoomId = chatRoom['chatRoomId'] as int;
                    final partnerCd = chatRoom['partnerCd'] as String;
                    final partnerId = chatRoom['partnerUserId'] as int;
                    final partnerUserNm = chatRoom['partnerUserNm'] as String?;
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline_outlined),
                      trailing: const Icon(Icons.navigate_next),
                      iconColor: Colors.green,
                      titleTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      title: Text(chatRoom['partnerNm'] as String? ?? '이름 없음'),
                      subtitle: Text('담당자: $partnerUserNm'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatRoomId: chatRoomId,
                              partnerCd: partnerCd,
                              partnerId: partnerId,
                              partnerUserNm: partnerUserNm,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
