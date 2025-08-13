import 'package:aetteullo_cust/provider/model/user.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/screen/mypage/user/user_info_edit_screen.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/etc/custom_container.dart';
import 'package:aetteullo_cust/widget/etc/info_field.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider에서 전역 사용자 데이터를 가져옵니다.
    final User user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '사용자 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showSearch: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 사용자 정보 표시 영역
            CustomContainer(
              child: Column(
                children: [
                  InfoField(
                    label: "아이디",
                    value: user.loginId,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "사용자명",
                    value: user.userNm,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "연락처",
                    value: user.phone,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "E-Mail",
                    value: user.email,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // '정보 수정' 버튼
            Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserInfoEditScreen(user: user),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('정보 수정'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
