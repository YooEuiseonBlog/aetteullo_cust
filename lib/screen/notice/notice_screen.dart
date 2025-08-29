import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/screen/notice/notice_dtl_screen.dart';
import 'package:aetteullo_cust/service/notice_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:aetteullo_cust/widget/nodata/no_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  late NoticeService _noticeService;
  List<Map<String, dynamic>> _noticeList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noticeService = NoticeService();
    _loadNoticeList();
  }

  Future<void> _loadNoticeList() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final rawList = await _noticeService.selectNoticeList();
      setState(() {
        _noticeList = rawList;
      });
    } on DioException catch (e) {
      debugPrint('err: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('알림 정보를 읽는 도중에 에러가 발생하였습니다.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppBar(title: '알림'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (_noticeList.isEmpty) {
              return NoData();
            } else {
              return ListView.builder(
                itemCount: _noticeList.length,
                itemBuilder: (context, index) {
                  final notice = _noticeList[index];
                  return _buildNoticeCard(notice: notice);
                },
              );
            }
          },
        ),
      ),
      bottomNavigationBar: MobileBottomNavigationBar(),
    );
  }

  Widget _buildNoticeCard({required Map<String, dynamic> notice}) {
    return Card.outlined(
      margin: EdgeInsets.only(bottom: 10),
      color: Colors.white70,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoticeDtlScreen(notice: notice)),
          );
        },
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
        leading: notice['limitYn'] == 'N'
            ? Icon(Icons.push_pin, size: 18, color: Colors.green)
            : SizedBox(),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 13,
          color: Colors.grey[600],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              // 추가: 텍스트 오버플로우 방지
              child: Text('[${notice['head']}] ${notice['headline']}'),
            ),
            Text(
              formatYyyyMMdd(notice['updtDate'], '-'),
              style: TextStyle(
                // 추가: 날짜 스타일링
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
