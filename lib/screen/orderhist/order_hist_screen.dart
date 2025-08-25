import 'dart:async';
import 'dart:convert';

import 'package:aetteullo_cust/constant/constants.dart';
import 'package:aetteullo_cust/function/color_utils.dart';
import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:aetteullo_cust/observer/route_observer.dart';
import 'package:aetteullo_cust/provider/user_provider.dart';
import 'package:aetteullo_cust/screen/orderhist/order_hist_dtl_screen.dart';
import 'package:aetteullo_cust/service/common_service.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:aetteullo_cust/service/order_service.dart';
import 'package:aetteullo_cust/service/sse_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/card/order_card.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:launchdarkly_event_source_client/launchdarkly_event_source_client.dart';
import 'package:provider/provider.dart';

class OrderHistScreen extends StatefulWidget {
  final int? tabIdx;
  const OrderHistScreen({super.key, this.tabIdx});

  @override
  State<OrderHistScreen> createState() => _OrderHistScreenState();
}

class _OrderHistScreenState extends State<OrderHistScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabController;
  bool _isLoading = false;

  // 날짜 선택용
  final List<DateTime?> _filterDates = [null, null];

  // 주문/취소 리스트
  List<Map<String, dynamic>> _orderList = [];
  List<Map<String, dynamic>> _cancelList = [];

  final OrderService _orderService = OrderService();
  final CommonService _commonService = CommonService();

  SSEService? _sseService;
  StreamSubscription<MessageEvent>? _sseSub;

  String _errorMessage = '';
  final String _topic = CUST_PO_STAT_TOPIC;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.tabIdx ?? 0,
    );
    _initSse();

    // 📌 초기화 시 둘 다 로딩
    _loadBothTabs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    // 아무것도 하지 않음 - 개별 onClickDtlBtn에서 처리
    _commonService.setNavIndex(context, 1);
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _sseService?.dispose();
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initSse() async {
    final token = await DioCookieClient().getJwtToken();
    if (token == null) return;

    try {
      _sseService?.dispose();
      _sseService = SSEService(token: token);
      final stream = await _sseService!.subscribe(_topic);

      await _sseSub?.cancel();
      _sseSub = stream.listen(
        _handleEvent,
        onError: (err, [st]) {
          debugPrint('🔥 SSE error: $err');
          _retryInit();
        },
        onDone: () {
          debugPrint('🏁 SSE connection closed by server');
          _retryInit();
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      debugPrint('❌ SSE subscribe failed: $e\n$st');
      _retryInit();
    }
  }

  void _handleEvent(MessageEvent evt) {
    if (_tabController.index != 0) return; // 📌 주문 탭에서만 반영
    if (evt.type != 'trigger') return;

    Map<String, dynamic>? dataMap;
    try {
      final s = evt.data.trim();
      if (s.isEmpty || !(s.startsWith('{') || s.startsWith('['))) return;
      final decoded = jsonDecode(s);
      if (decoded is! Map) return;
      dataMap = (decoded).cast<String, dynamic>();
    } catch (_) {
      return;
    }

    final poNo = dataMap['poNo'] as String? ?? '';
    final stat = dataMap['stat'] as String? ?? '';
    final statNm = dataMap['statNm'] as String? ?? '';
    final fixYn = dataMap['fixYn'] as String? ?? '';

    if (!mounted || poNo.isEmpty) return;
    setState(() {
      final idx = _orderList.indexWhere((e) => e['poNo'] == poNo);
      if (idx != -1) {
        _orderList[idx]['stat'] = stat;
        _orderList[idx]['statNm'] = statNm;
        _orderList[idx]['fixYn'] = fixYn;
      }
    });
  }

  void _retryInit() {
    _sseService?.dispose();
    _sseSub?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _initSse();
    });
  }

  /// 📌 초기 로딩: 둘 다 동시에 로드 (mounted 체크 추가)
  Future<void> _loadBothTabs() async {
    if (_isLoading || !mounted) return;
    setState(() => _isLoading = true);

    try {
      // 📌 병렬로 둘 다 로드
      final results = await Future.wait([
        _orderService.selectPoList(poDate: _filterDates[0]),
        _orderService.getCancelPoList(clDate: _filterDates[1]),
      ]);

      // ⚠️ await 후 반드시 mounted 체크
      if (!mounted) return;

      setState(() {
        _orderList = results[0];
        _cancelList = results[1];
        _errorMessage = '';
      });

      debugPrint(
        '📊 로딩 완료: 주문 ${_orderList.length}건, 취소 ${_cancelList.length}건',
      );
    } catch (e) {
      debugPrint('❌ 로딩 실패: $e');

      // ⚠️ catch에서도 mounted 체크
      if (!mounted) return;

      setState(() {
        _orderList = [];
        _cancelList = [];
        _errorMessage = '데이터를 불러오는 데 실패했습니다.';
      });
    } finally {
      // ⚠️ finally에서도 mounted 체크
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 📌 개별 탭 로딩 (필터 변경 시)
  Future<void> _loadForTab(int idx) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final selected = _filterDates[idx];
    try {
      if (idx == 0) {
        _orderList = await _orderService.selectPoList(poDate: selected);
        debugPrint('📊 주문 데이터 로드 완료: ${_orderList.length}건');
      } else {
        _cancelList = await _orderService.getCancelPoList(clDate: selected);
        debugPrint('📊 취소 데이터 로드 완료: ${_cancelList.length}건');
      }
      setState(() => _errorMessage = '');
    } catch (e) {
      debugPrint('❌ 탭 $idx 로드 오류: $e');
      setState(() {
        if (idx == 0) {
          _orderList = [];
        } else {
          _cancelList = [];
        }
        _errorMessage = '데이터를 불러오는 데 실패했습니다.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formattedChip(int idx) {
    final d = _filterDates[idx];
    return d != null ? DateFormat('yyyy-MM-dd').format(d) : '';
  }

  Future<void> _pickDate(int idx) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDates[idx] ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _filterDates[idx] = picked);
      await _loadForTab(idx);
    }
  }

  void _clearDate(int idx) {
    setState(() => _filterDates[idx] = null);
    _loadForTab(idx);
  }

  Widget _buildFilterBar() {
    final currentTabIndex = _tabController.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (_filterDates[currentTabIndex] != null) ...[
            Chip(
              backgroundColor: Colors.white,
              label: Text(_formattedChip(currentTabIndex)),
              onDeleted: () => _clearDate(currentTabIndex),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () => _pickDate(currentTabIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent({required List<Map<String, dynamic>> list}) {
    // 📌 로딩 중
    if (_isLoading) {
      return Column(
        children: [
          _buildFilterBar(),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    // 📌 데이터가 비어있을 때
    if (list.isEmpty) {
      return Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Center(
              child: Text(
                _errorMessage.isNotEmpty ? _errorMessage : '데이터가 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      );
    }

    // 📌 데이터가 있을 때
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = list[index];
              final poDate = order['poDate'] as String? ?? '';

              final items = (order['item'] as List<dynamic>)
                  .cast<Map<String, dynamic>>();

              final first = items.isNotEmpty ? items.first : null;
              final title =
                  (first?['itemNm'] ?? '') +
                  (items.length > 1 ? ' 외 ${items.length - 1}건' : '');
              final img = first?['image1'] ?? '';
              final amt = items.fold<double>(
                0,
                (s, e) => s + (e['amnt'] as double? ?? 0),
              );
              final stat = order['stat'] as String? ?? '';
              final statNm = order['statNm'] as String? ?? '';

              return OrderCard(
                margin: const EdgeInsets.only(bottom: 5),
                title: title,
                receiver: context.read<UserProvider>().user.userNm,
                subDate: order['clDate'] != null
                    ? formatYyyyMMdd(order['clDate'], '.')
                    : null,
                image: img,
                amount: amt,
                stat: statNm,
                color: getPoStatusColor(stat),
                cnt: items.length.toDouble(),
                date: poDate,
                onClickDtlBtn: () async {
                  final currentTabIndex =
                      _tabController.index; // 📌 현재 탭 인덱스 저장

                  final stat = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderHistDtlScreen(orderInfo: order),
                    ),
                  );

                  // 📌 주문 탭(index 0)에서만 둘 다 로딩
                  if (currentTabIndex == 0) {
                    debugPrint('📊 주문 탭에서 상세 돌아옴 - 둘 다 다시 로드');
                    _loadBothTabs();
                  }

                  // 📌 상태 변경이 있었다면 해당 탭으로 이동
                  if (stat != null) {
                    final targetIdx = stat == '1' ? 1 : 0;
                    _tabController.animateTo(targetIdx);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MobileAppBar(
        title: Text(
          '주문내역',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        showSearch: false,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0CC377),
            labelColor: const Color(0xFF0CC377),
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 10),
            tabs: const [
              Tab(text: '주문'),
              Tab(text: '취소'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(list: _orderList),
                _buildTabContent(list: _cancelList),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
