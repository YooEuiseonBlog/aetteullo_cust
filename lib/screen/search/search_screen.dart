import 'package:aetteullo_cust/screen/search/search_rst_screen.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final String? keyword;
  const SearchScreen({super.key, this.keyword});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // SharedPreferences에 저장할 때 사용할 키
  static const String _kRecentSearchesKey = 'recent_searches';

  // 최근 검색어 리스트
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword ?? '';
    _loadRecentSearchesFromPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// SharedPreferences에서 최근 검색어 리스트를 불러오기
  Future<void> _loadRecentSearchesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(_kRecentSearchesKey) ?? [];
    setState(() {
      _recentSearches = savedList;
    });
  }

  /// SharedPreferences에 최근 검색어 리스트를 저장하기
  Future<void> _saveRecentSearchesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentSearchesKey, _recentSearches);
  }

  /// 검색어 제출 시 호출
  void _onSearchSubmitted(String query) {
    final term = query.trim();
    if (term.isEmpty) return;

    setState(() {
      // 이미 존재하는 검색어라면 먼저 제거
      _recentSearches.removeWhere((e) => e == term);

      // 새로운 검색어를 리스트 맨 앞에 삽입
      _recentSearches.insert(0, term);

      // 최대 10개까지만 저장
      if (_recentSearches.length > 10) {
        _recentSearches.removeRange(10, _recentSearches.length);
      }
    });

    // 변경된 리스트를 SharedPreferences에 저장
    _saveRecentSearchesToPrefs();

    // 텍스트 필드 비우기
    _searchController.clear();

    // TODO: SearchRstScreen의 실제 경로에 맞게 import 경로를 조정해주세요.
    // 검색 결과 화면으로 이동하며, 검색어(term)를 전달
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchRstScreen(searchKeyword: term)),
    );
  }

  /// 최근 검색어 리스트에서 개별 항목 삭제
  void _removeRecentSearch(int index) {
    setState(() {
      _recentSearches.removeAt(index);
    });
    _saveRecentSearchesToPrefs();
  }

  /// 최근 검색어 전체 삭제
  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearchesToPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar 대신 검색창을 상단에 배치
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // 뒤로가기 버튼
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                // 검색 입력창
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            // 엔터(검색) 키를 눌렀을 때 동작
                            onSubmitted: _onSearchSubmitted,
                            decoration: const InputDecoration(
                              hintText: '검색어를 입력해 주세요.',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // 최근 검색어 헤더 (전체 삭제 버튼 포함)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '최근 검색어',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (_recentSearches.isNotEmpty)
                  TextButton(
                    onPressed: _clearAllRecentSearches,
                    child: const Text(
                      '전체삭제',
                      style: TextStyle(fontSize: 14, color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),

          // 최근 검색어 리스트 혹은 빈 상태 메시지
          Expanded(
            child: _recentSearches.isEmpty
                ? const Center(
                    child: Text(
                      '최근 검색어가 없습니다.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _recentSearches.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (context, index) {
                      final term = _recentSearches[index];
                      return ListTile(
                        title: Text(term, style: const TextStyle(fontSize: 16)),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () => _removeRecentSearch(index),
                        ),
                        onTap: () {
                          // 해당 검색어를 탭하면 바로 검색 결과 화면으로 이동
                          _onSearchSubmitted(term);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      bottomNavigationBar: const MobileBottomNavigationBar(),
    );
  }
}
