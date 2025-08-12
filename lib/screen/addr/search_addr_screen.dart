// lib/screens/search_addr_screen.dart

import 'package:aetteullo_cust/model/address_model.dart';
import 'package:aetteullo_cust/service/address_service.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:aetteullo_cust/widget/navigationbar/mobile_bottom_navigation_bar.dart';
import 'package:aetteullo_cust/widget/nodata/no_data.dart';
import 'package:flutter/material.dart';

class SearchAddrScreen extends StatefulWidget {
  const SearchAddrScreen({super.key});

  @override
  State<SearchAddrScreen> createState() => _SearchAddrScreenState();
}

class _SearchAddrScreenState extends State<SearchAddrScreen> {
  final TextEditingController _keywordController = TextEditingController();
  final AddressService _service = AddressService();

  bool _isLoading = false;
  bool _hasSearched = false; // 검색 시도를 추적
  List<Juso> _results = [];
  String? _error;

  Future<void> _doSearch() async {
    final keyword = _keywordController.text.trim();
    setState(() {
      _hasSearched = true;
      _error = null;
      _results = [];
    });

    if (keyword.isEmpty) {
      setState(() {
        _error = '검색어를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resp = await _service.searchAddress(
        keyword: keyword,
        currentPage: 1,
        countPerPage: 20,
      );
      setState(() {
        _results = resp.juso;
      });
    } catch (e) {
      setState(() {
        _error = '주소 검색 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const MobileAppBar(
        title: Text(
          '주소 검색',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 검색창
            TextField(
              controller: _keywordController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '도로명 또는 건물명 입력',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _doSearch,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
            const SizedBox(height: 12),
            // 검색 결과 영역
            Expanded(
              child: Builder(
                builder: (_) {
                  if (!_hasSearched) {
                    return const Center(
                      child: Text(
                        '주소를 검색해주세요.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_error != null) {
                    return Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (_results.isEmpty) {
                    return NoData();
                  }
                  // 실제 검색 결과 리스트
                  return ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        title: Text(item.roadAddr),
                        subtitle: Text(item.jibunAddr),
                        onTap: () => Navigator.of(context).pop<Juso>(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
