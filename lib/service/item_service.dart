import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ItemService {
  // 좋아요(관심) 토글
  Future<void> toggleLikeState({required int itemId}) async {
    try {
      await DioCookieClient.http.post('/mobile/item/like/$itemId');
    } on DioException catch (e) {
      debugPrint('toggleLikeState error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchItemList({
    String? itemNm,
    String? fixCtgry,
    List<int>? unitIds,
    List<String>? origins,
    List<String>? mnfcts,
    List<String>? mainCtgries,
    List<String>? midCtgries,
    List<String>? subCtgries,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortDir,
  }) async {
    // 1) 쿼리 파라미터 구성
    final query = <String, dynamic>{
      if (fixCtgry != null && fixCtgry.isNotEmpty) 'fixCtgry': fixCtgry,
      if (itemNm != null && itemNm.isNotEmpty) 'itemNm': itemNm,
      if (unitIds != null && unitIds.isNotEmpty) 'unitIds': unitIds,
      if (origins != null && origins.isNotEmpty) 'origins': origins,
      if (mnfcts != null && mnfcts.isNotEmpty) 'mnfcts': mnfcts,
      if (mainCtgries != null && mainCtgries.isNotEmpty)
        'mainCtgries': mainCtgries,
      if (midCtgries != null && midCtgries.isNotEmpty) 'midCtgries': midCtgries,
      if (subCtgries != null && subCtgries.isNotEmpty) 'subCtgries': subCtgries,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (sortDir != null && sortDir.isNotEmpty) 'sortDir': sortDir,
    };

    final resp = await DioCookieClient.http.get<List<dynamic>>(
      '/mobile/item',
      queryParameters: query,
    );

    return (resp.data ?? []).cast();
  }

  Future<List<Map<String, dynamic>>> getRandomItemList({int count = 5}) async {
    try {
      final response = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/item/rand',
        queryParameters: {'count': count},
      );
      final data = response.data;

      return (data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception('Failed to fetch random items: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Data parsing failed: ${e.message}');
    }
  }

  /// 서버에서 “최근 7일 이내 주문 아이템” 리스트를 조회합니다.
  /// GET /mobile/order/item
  Future<List<Map<String, dynamic>>> getLatestPoItemList() async {
    try {
      // GET 요청
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/item/order',
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('getLatestPoItemList Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getLatestPoItemList unexpected error: $e');
      rethrow;
    }
  }

  // 사용자가 좋아요 표기한 아이템 리스트 조회
  Future<List<Map<String, dynamic>>> getLikeItemList() async {
    try {
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/item/like',
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('getLikeItemList Dio error: ${e.message}');
      rethrow;
    } on FormatException catch (e) {
      throw Exception('Data parsing failed: ${e.message}');
    }
  }

  /// 세트 아이템 리스트 조회
  /// GET /mobile/item/set?setNm={setNm}
  Future<List<Map<String, dynamic>>> getItemSetList({
    String? setNm,
    String? itemNm,
  }) async {
    final query = <String, dynamic>{
      if (setNm != null && setNm.trim().isNotEmpty) 'setNm': setNm,
      if (itemNm != null && itemNm.trim().isNotEmpty) 'itemNm': itemNm,
    };

    try {
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/item/set',
        queryParameters: query,
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('getItemSetList Dio error: ${e.message}');
      rethrow;
    } on FormatException catch (e) {
      throw Exception('Data parsing failed: ${e.message}');
    }
  }

  /// 새로운 세트 등록
  /// POST /mobile/item/set
  Future<void> saveItemSet({
    required List<Map<String, dynamic>> items,
    required String setNm,
  }) async {
    final body = {'items': items, 'setNm': setNm};
    try {
      await DioCookieClient.http.post('/mobile/item/set', data: body);
    } on DioException catch (e) {
      debugPrint('saveItemSet Dio error: ${e.message}');
      rethrow;
    }
  }

  /// 기존 세트 수정
  /// POST /mobile/item/set/{setId}
  Future<void> updateItemSet({
    required int setId,
    required List<Map<String, dynamic>> items,
    required String setNm,
  }) async {
    final body = {'items': items, 'setNm': setNm};
    try {
      await DioCookieClient.http.post('/mobile/item/set/$setId', data: body);
    } on DioException catch (e) {
      debugPrint('updateItemSet Dio error: ${e.message}');
      rethrow;
    }
  }

  /// 세트 삭제
  /// DELETE /mobile/item/set/{setId}
  Future<void> deleteItemSet({required int setId}) async {
    try {
      await DioCookieClient.http.delete('/mobile/item/set/$setId');
    } on DioException catch (e) {
      debugPrint('deleteItemSet Dio error: ${e.message}');
      rethrow;
    }
  }

  Future<void> deleteItemSets({required List<int> setIds}) async {
    try {
      await DioCookieClient.http.delete(
        '/mobile/item/set/list',
        data: <String, dynamic>{'setIds': setIds},
      );
    } on DioException catch (e) {
      debugPrint('deleteItemSet Dio error: ${e.message}');
      rethrow;
    }
  }
}
