import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class NoticeDtlScreen extends StatefulWidget {
  final Map<String, dynamic> notice;
  const NoticeDtlScreen({super.key, required this.notice});

  @override
  State<NoticeDtlScreen> createState() => _NoticeDtlScreenState();
}

class _NoticeDtlScreenState extends State<NoticeDtlScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppBar(title: '알림 정보'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 + 고정 아이콘 + 등록일
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 고정 아이콘 (고정공지인 경우에만)
                      if (widget.notice['limitYn'] == 'N') ...[
                        Icon(Icons.push_pin, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                      ],
                      // 제목
                      Expanded(
                        child: Text(
                          '[${widget.notice['head']}] ${widget.notice['headline'] ?? '제목 없음'}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // 등록일
                Text(
                  formatYyyyMMdd(widget.notice['insrtDate'], '-'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 24),

            // 내용
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.notice['content'] ?? '내용이 없습니다.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),

            // 첨부파일 (있는 경우에만)
            if (widget.notice['attch1'] != null &&
                widget.notice['attch1'].toString().isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(child: Text(widget.notice['attch1'])),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: MobileBottomNavigationBar(),
    );
  }
}
