import 'dart:async';

import 'package:aetteullo_cust/constant/constants.dart';
import 'package:aetteullo_cust/function/color_utils.dart';
import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/screen/deli/deli_dtl_screen.dart';
import 'package:aetteullo_cust/service/deli_service.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:aetteullo_cust/service/rtn_service.dart';
import 'package:aetteullo_cust/service/sse_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliScreen extends StatefulWidget {
  const DeliScreen({super.key});

  @override
  State<DeliScreen> createState() => _DeliScreenState();
}

class _DeliScreenState extends State<DeliScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeliService _deliService = DeliService();
  final RtnService _rtnService = RtnService();
  final String _topic = CUST_DELI_STAT_TOPIC;
  late SSEService _sseService;
  late StreamSubscription<SseEvent> _sseSub;

  List<Map<String, dynamic>> _deliList = [];
  List<Map<String, dynamic>> _rtnList = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          if (_tabController.index == 0) {
            _getDeliList();
          } else {
            _getRtnList();
          }
        }
      });
    _initSse();
    _getDeliList();
  }

  void _initSse() async {
    try {
      final token = await DioCookieClient().getJwtToken();
      if (token == null) return;
      _sseService = SSEService(token: token);
      final stream = await _sseService.subscribe(_topic);
      _sseSub = stream.listen(
        _handleEvent,
        onError: (err) {
          debugPrint('🔥 SSE error: $err');
          _retryInit();
        },
        onDone: () {
          debugPrint('🏁 SSE connection closed by server');
          _retryInit();
        },
        cancelOnError: false,
      );
    } on Exception catch (e) {
      debugPrint('❌ SSE subscribe failed: $e');
      // _retryInit();
    }
  }

  void _handleEvent(SseEvent evt) {
    if (evt.event == 'trigger') {
      debugPrint('sse 연결 수신 완료');
      // evt.data가 Map<dynamic, dynamic>일 때
      final raw = evt.data as Map<dynamic, dynamic>;
      final Map<String, dynamic> dataMap = raw.cast<String, dynamic>();
      final deliCd = dataMap['deliCd'] as String;
      final stat = dataMap['stat'] as String;
      final statNm = dataMap['statNm'] as String;

      // 2) setState 내부에서 리스트를 검색·수정
      setState(() {
        // (a) 주문 탭(_orderList)에 있을 경우
        final idx = _deliList.indexWhere((e) => e['deliCd'] == deliCd);
        if (idx != -1) {
          _deliList[idx]['stat'] = stat;
          _deliList[idx]['statNm'] = statNm;
        }
      });
    }
  }

  void _retryInit() {
    _sseSub.cancel();
    Future.delayed(const Duration(seconds: 5), _initSse);
  }

  Future<void> _getDeliList() async {
    try {
      _deliList = await _deliService.getDeliList(deliDate: _selectedDate);
    } catch (e) {
      debugPrint('_getDeliList err: $e');
      _deliList = [];
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _getRtnList() async {
    try {
      _rtnList = await _rtnService.getRtnList(rtnDate: _selectedDate);
    } catch (e) {
      debugPrint('$e');
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_tabController.index == 0) {
        await _getDeliList();
      } else {
        await _getRtnList();
      }
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    if (_tabController.index == 0) {
      _getDeliList();
    } else {
      _getRtnList();
    }
  }

  String get _formattedDateChip {
    if (_selectedDate == null) return '';
    return DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  @override
  void dispose() {
    _sseSub.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildDeliCard(Map<String, dynamic> map) {
    final dateStr =
        (map['deliDate'] is String && (map['deliDate'] as String).isNotEmpty)
        ? formatYyyyMMdd(map['deliDate'], '-')
        : '-';
    final codeStr = map['deliCd'] as String? ?? '';
    final compStr = map['deliComNm'] as String? ?? '';
    final divRaw = map['deliDiv'] as String? ?? '';
    final divStr = map['deliDivNm'] as String? ?? '';
    final stat = map['stat'];
    final statColor = getDeliStatColor(stat);
    final statStr = map['statNm'] as String? ?? '';

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeliDtlScreen(deliMap: map)),
        );
        _getDeliList();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  codeStr,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('업체'), Text(compStr)],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('구분'),
                Text(
                  divStr,
                  style: TextStyle(
                    color: divRaw == '1' ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('상태'),
                Text(
                  statStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRtnCard(Map<String, dynamic> map) {
    final rtnDateStr =
        (map['rtnDate'] is String && (map['rtnDate'] as String).isNotEmpty)
        ? formatYyyyMMdd(map['rtnDate'], '-')
        : '-';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                map['itemNm'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                rtnDateStr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8), // 모서리 반경
                child: CachedNetworkImage(
                  imageUrl: map['image1'] ?? '',
                  width: 100, // 원하는 썸네일 가로 크기
                  height: 100, // 원하는 썸네일 세로 크기
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100, // 원하는 썸네일 가로 크기
                    height: 100, // 원하는 썸네일 세로 크기
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100, // 원하는 썸네일 가로 크기
                    height: 100, // 원하는 썸네일 세로 크기
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('주문번호'),
                        Text(
                          map['poNo'] as String? ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('배송일'),
                        Text(
                          map['deliDate'] as String? ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('주문수량'),
                        Text(
                          '${(map['poQty'] as num? ?? 0.0).toInt()}개',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('반품수량'),
                        Text(
                          '${(map['rtnQty'] as num).toInt()}개',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '배송 관리',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        showSearch: false,
      ),
      body: Column(
        children: [
          // 탭 바
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0CC377),
            labelColor: const Color(0xFF0CC377),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: '배송'),
              Tab(text: '반품'),
            ],
          ),

          // 날짜 필터
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (_selectedDate != null) ...[
                  Chip(
                    backgroundColor: Colors.white,
                    label: Text(_formattedDateChip),
                    deleteIcon: const Icon(Icons.clear, size: 18),
                    onDeleted: _clearDate,
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _deliList.isEmpty
                    ? Center(
                        child: Text(
                          '데이터가 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _deliList.length,
                        itemBuilder: (_, i) => _buildDeliCard(_deliList[i]),
                      ),
                _rtnList.isEmpty
                    ? Center(
                        child: Text(
                          '데이터가 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _rtnList.length,
                        itemBuilder: (_, i) => _buildRtnCard(_rtnList[i]),
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
