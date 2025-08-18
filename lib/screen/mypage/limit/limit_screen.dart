import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/service/user_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class LimitScreen extends StatefulWidget {
  const LimitScreen({super.key});

  @override
  State<LimitScreen> createState() => _LimitScreenState();
}

class _LimitScreenState extends State<LimitScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  double? _creditLimitApp;
  double? _creditLimitAmnt;
  final bool _isEditing = false;

  late TextEditingController _appController;
  late TextEditingController _amntController;

  @override
  void initState() {
    super.initState();
    _appController = TextEditingController();
    _amntController = TextEditingController();
    _fetchCreditInfo();
  }

  @override
  void dispose() {
    _appController.dispose();
    _amntController.dispose();
    super.dispose();
  }

  Future<void> _fetchCreditInfo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final creditInfo = await _userService.getIndustLimit();
      if (creditInfo != null) {
        final rawAmnt = creditInfo['creditLimitAmnt'];
        final rawApp = creditInfo['creditLimitApp'];

        if (rawAmnt != null) {
          _creditLimitAmnt = (rawAmnt is num)
              ? rawAmnt.toDouble()
              : double.tryParse(rawAmnt.toString());
        } else {
          _creditLimitAmnt = null;
        }

        if (rawApp != null) {
          _creditLimitApp = (rawApp is num)
              ? rawApp.toDouble()
              : double.tryParse(rawApp.toString());
        } else {
          _creditLimitApp = null;
        }
      } else {
        _creditLimitAmnt = null;
        _creditLimitApp = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신용 한도 정보를 가져오는 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '외상한도 관리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        showSearch: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _isEditing
                            ? _buildEditableRow(
                                label: '외상 한도 기간',
                                controller: _appController,
                                suffix: '일',
                                keyboardType: TextInputType.number,
                              )
                            : _buildTextRow(
                                prefixTxt: '외상 한도 기간',
                                suffixTxt: _creditLimitApp != null
                                    ? '${_creditLimitApp!.floor()}일'
                                    : '데이터 없음',
                              ),
                        const SizedBox(height: 5),
                        _isEditing
                            ? _buildEditableRow(
                                label: '외상 한도 금액',
                                controller: _amntController,
                                suffix: '원',
                                keyboardType: TextInputType.number,
                              )
                            : _buildTextRow(
                                removeUnderline: true,
                                prefixTxt: '외상 한도 금액',
                                suffixTxt: _creditLimitAmnt != null
                                    ? '${formatCurrency(_creditLimitAmnt ?? 0)}원'
                                    : '데이터 없음',
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

  Container _buildTextRow({
    required String prefixTxt,
    required String suffixTxt,
    bool removeUnderline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: removeUnderline
              ? BorderSide.none
              : BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1.0,
                ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            prefixTxt,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            suffixTxt,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Container _buildEditableRow({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required TextInputType keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 4,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                suffixText: suffix,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
