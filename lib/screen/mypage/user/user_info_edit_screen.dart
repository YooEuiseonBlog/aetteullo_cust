import 'package:aetteullo_cust/formatter/formatter.dart';
import 'package:aetteullo_cust/provider/model/user.dart';
import 'package:aetteullo_cust/service/common_service.dart';
import 'package:aetteullo_cust/service/user_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/etc/custom_container.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserInfoEditScreen extends StatefulWidget {
  final User user;

  const UserInfoEditScreen({super.key, required this.user});

  @override
  State<UserInfoEditScreen> createState() => _UserInfoEditScreenState();
}

class _UserInfoEditScreenState extends State<UserInfoEditScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final UserService _userService = UserService();
  final CommonService _commonService = CommonService();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _idController.text = widget.user.loginId;
    _nameController.text = widget.user.userNm;
    _phoneController.text = widget.user.phone;
    _emailController.text = widget.user.email;
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 저장 버튼 클릭 시 DB 업데이트 → 최신 사용자 정보 읽기 → Provider 업데이트 → 화면 pop
  Future<void> _saveUserInfo() async {
    if (_isSaving) return;

    if (_idController.text.trim().isEmpty) {
      _showSnackBar('아이디를 입력해주세요.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('사용자명을 입력해주세요.');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('연락처를 입력해주세요.');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('이메일을 입력해주세요.');
      return;
    }
    if (_passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('비밀번호가 일치하지 않습니다.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateUser(
        email: _emailController.text,
        phone: _phoneController.text,
        passwd: _passwordController.text,
      );

      if (mounted) {
        _commonService.fetchUser(context);
      }

      _showSnackBar('정보가 성공적으로 저장되었습니다.');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('오류가 발생했습니다.\n$e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '사용자 정보 변경',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showSearch: false,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('아이디'),
                  TextField(
                    readOnly: true,
                    controller: _idController,
                    decoration: const InputDecoration(isDense: true),
                  ),
                  const SizedBox(height: 25),
                  const Text('비밀번호 변경'),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(isDense: true),
                  ),
                  const SizedBox(height: 25),
                  const Text('비밀번호 확인'),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(isDense: true),
                  ),
                  const SizedBox(height: 25),
                  const Text('사용자명'),
                  TextField(
                    readOnly: true,
                    controller: _nameController,
                    decoration: const InputDecoration(isDense: true),
                  ),
                  const SizedBox(height: 25),
                  const Text('연락처'),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneNumberFormatter(), // 별도의 파일에서 임포트한 포맷터 사용
                    ],
                    decoration: const InputDecoration(isDense: true),
                  ),
                  const SizedBox(height: 25),
                  const Text('E-Mail'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
