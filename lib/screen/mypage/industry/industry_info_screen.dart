import 'package:aetteullo_cust/provider/model/user.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/etc/custom_container.dart';
import 'package:aetteullo_cust/widget/etc/info_field.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class IndustryInfoScreen extends StatelessWidget {
  final User user;
  const IndustryInfoScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: const MobileAppBar(
        title: Text(
          '사업장 정보',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomContainer(
              child: Column(
                children: [
                  InfoField(
                    label: "사업자명",
                    value: user.industNm,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "담당자 연락처",
                    value: user.phone,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "주소",
                    value: '${user.addr}\n${user.addrDtl}',
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "대표자명",
                    value: user.ownerNm,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "업종",
                    value: user.bizKind,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "업태",
                    value: user.bizType,
                    fontWeight: FontWeight.bold,
                    removeUnderline: true,
                  ),
                  const SizedBox(height: 8),
                  InfoField(
                    label: "대표번호",
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
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
