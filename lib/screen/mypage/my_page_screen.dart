import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/screen/login/login_screen.dart';
import 'package:aetteullo_cust/screen/mypage/chat/chat_room_screen.dart';
import 'package:aetteullo_cust/screen/mypage/industry/industry_info_screen.dart';
import 'package:aetteullo_cust/screen/mypage/itemset/item_set_list_screen.dart';
import 'package:aetteullo_cust/screen/mypage/limit/limit_screen.dart';
import 'package:aetteullo_cust/screen/mypage/refund/refund_screen.dart';
import 'package:aetteullo_cust/screen/mypage/user/user_info_screen.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().user;
    if (user.isEmpty) {
      return const Scaffold(
        appBar: MobileAppBar(title: Text('마이페이지'), showSearch: false),
        body: Center(child: Text('사용자 정보를 불러오지 못했습니다.')),
      );
    }

    return Scaffold(
      appBar: const MobileAppBar(
        title: Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showSearch: false,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        user.userNm,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: 32,
                      thickness: 1,
                      color: Color(0xFFE0E0E0),
                    ),
                    Center(
                      child: Text(
                        user.gradeNm,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListMenuItem(
                  icon: Icons.business,
                  label: '사업장 정보',
                  iconColor: Colors.blue,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IndustryInfoScreen(user: user),
                      ),
                    );
                  },
                ),
                ListMenuItem(
                  icon: Icons.receipt,
                  label: '환불 계좌 정보',
                  iconColor: Colors.purple,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RefundScreen()),
                    );
                  },
                ),
                ListMenuItem(
                  icon: Icons.person,
                  label: '사용자 정보',
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserInfoScreen()),
                    );
                  },
                ),
                ListMenuItem(
                  icon: Icons.plus_one,
                  label: '외상한도 조회',
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LimitScreen()),
                    );
                  },
                ),
                ListMenuItem(
                  icon: Icons.layers,
                  label: '세트아이템',
                  iconColor: Colors.teal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ItemSetListScreen(),
                      ),
                    );
                  },
                ),
                // ListMenuItem(
                //   icon: Icons.support_agent,
                //   label: '고객센터',
                //   iconColor: Colors.blueGrey,
                //   onTap: () {
                //     // Navigator.of(context).push(
                //     //   MaterialPageRoute(builder: (_) => const QnaMenuScreen()),
                //     // );
                //   },
                // ),
                ListMenuItem(
                  icon: Icons.chat_bubble,
                  label: '채팅',
                  iconColor: Colors.green,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatRoomScreen()),
                    );
                  },
                ),
                ListMenuItem(
                  icon: Icons.logout,
                  label: '로그아웃',
                  iconColor: Colors.red,
                  onTap: () async {
                    // 1) 로그아웃 확인 다이얼로그
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('로그아웃'),
                        content: const Text('정말 로그아웃 하시겠습니까?'),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );

                    // 2) “확인” 선택 시에만 실제 로그아웃 실행
                    if (shouldLogout == true) {
                      await DioCookieClient().logout();

                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}

class ListMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const ListMenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
