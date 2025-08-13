import 'package:aetteullo_cust/formatter/formatter.dart';
import 'package:aetteullo_cust/service/common_service.dart';
import 'package:aetteullo_cust/service/user_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _bankList = [];
  String? _selectedBankKey;

  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  final UserService _userService = UserService();
  final CommonService _commonService = CommonService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadBankList();
    await _loadAccountInfo();
  }

  @override
  void dispose() {
    _accountNoController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadBankList() async {
    try {
      final list = await _commonService.getBankInfo();
      setState(() {
        _bankList = [
          {'name': '선택', 'key': null},
          ...list,
        ];
        _selectedBankKey = null;
      });
    } catch (e) {
      debugPrint('[Refund] _loadBankList error: $e');
      _showSnackBar('은행 목록을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 2. 저장된 계좌 정보 로드 (null 허용, Map 직접 사용)
  Future<void> _loadAccountInfo() async {
    try {
      final json = await _userService.getAccountInfo();
      if (json == null || json.isEmpty) {
        // 저장된 정보 없음
        setState(() {
          _selectedBankKey = null;
          _accountNoController.clear();
          _accountHolderController.clear();
        });
        return;
      }

      final bankDiv = json['bankDiv'] as String?;
      final rawAcctNo = json['bankAcctNo'] as String? ?? '';
      final holder = json['acctNm'] as String? ?? '';

      // 계좌번호 포맷팅
      final formatted = AccountNumberFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: rawAcctNo),
          )
          .text;

      setState(() {
        _selectedBankKey = _bankList.any((b) => b['key'] == bankDiv)
            ? bankDiv
            : null;
        _accountNoController.text = formatted;
        _accountHolderController.text = holder;
      });
    } catch (e) {
      debugPrint('[Refund] _loadAccountInfo error: $e');
      _showSnackBar('계좌 정보를 불러오는데 실패했습니다.');
    }
  }

  Future<void> _saveAccount() async {
    if (_isLoading) return;

    if (_selectedBankKey == null) {
      _showSnackBar('은행을 선택해주세요.');
      return;
    }
    if (_accountNoController.text.trim().isEmpty) {
      _showSnackBar('계좌번호를 입력해주세요.');
      return;
    }
    if (_accountHolderController.text.trim().isEmpty) {
      _showSnackBar('예금주명을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    final accountNo = _accountNoController.text
        .replaceAll(RegExp(r'[\s-]'), '')
        .trim();

    try {
      await _userService.saveAccountInfo(
        bankDiv: _selectedBankKey!,
        bankAcctNo: accountNo,
        acctNm: _accountHolderController.text.trim(),
      );
      await _loadAccountInfo();
      _showSnackBar('계좌 정보가 저장되었습니다.');
    } catch (e) {
      debugPrint('[Refund] saveAccount error: $e');
      _showSnackBar('계좌 정보 저장에 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: false,
      appBar: const MobileAppBar(
        title: Text(
          '환불 계좌 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showSearch: false,
      ),
      body: _buildForm(),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }

  Widget _buildForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('은행명', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                prefixIcon: Icon(
                  Icons.account_balance,
                  size: 25,
                  color: Colors.grey,
                ),
              ),
              value: _selectedBankKey,
              items: _bankList.map((bank) {
                return DropdownMenuItem<String?>(
                  value: bank['key'] as String?,
                  child: Text(bank['name'] as String),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedBankKey = v),
            ),
          ),
          const SizedBox(height: 20),
          const Text('계좌번호', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextFormField(
              controller: _accountNoController,
              inputFormatters: [AccountNumberFormatter()],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(
                  Icons.confirmation_number,
                  size: 25,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('예금주명', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextFormField(
              controller: _accountHolderController,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.person, size: 25, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                side: BorderSide.none,
              ),
              onPressed: _isLoading ? null : _saveAccount,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    )
                  : const Text(
                      '저장',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
