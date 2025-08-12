import 'package:aetteullo_cust/service/common_service.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class BasketService {
  Future<List<Map<String, dynamic>>> selectBasketItemList() async {
    try {
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/basket',
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e, stackTrace) {
      debugPrint('getBkList error: $e\n$stackTrace');
      rethrow;
    }
  }

  /// 지정된 itemIds 리스트로 장바구니 아이템 일괄 삭제 요청
  Future<void> _deleteBasketItems({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await DioCookieClient.http.delete(
        '/mobile/basket',
        data: {'items': items},
      );
    } on DioException catch (e, stackTrace) {
      debugPrint('deleteBkItems error: $e\n$stackTrace');
      rethrow;
    }
  }

  /// 장바구니에 아이템들을 저장합니다.
  /// 서버가 204 No Content 를 반환한다고 가정합니다.
  Future<void> _saveBasketItems({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await DioCookieClient.http.post('/mobile/basket', data: {'items': items});
    } on DioException catch (e) {
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('알 수 없는 오류: $e');
    }
  }

  Future<void> _updateBasketItems({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await DioCookieClient.http.put(
        '/mobile/basket',
        data: {'items': items},
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      throw Exception('네트워크 오류: ${e.message}');
    } catch (e) {
      throw Exception('알 수 없는 오류: $e');
    }
  }

  Future<void> saveBasketItems({
    required List<Map<String, dynamic>> items,
    required BuildContext context,
  }) async {
    try {
      await _saveBasketItems(items: items);
      if (context.mounted) {
        await CommonService().fetchBasketCnt(context, showErrorMsg: false);
      }
    } catch (e, stackTrace) {
      debugPrint('[_addBasketItem] Error: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<void> deleteBasketItems({
    required List<Map<String, dynamic>> items,
    required BuildContext context,
  }) async {
    try {
      await _deleteBasketItems(items: items);
      if (context.mounted) {
        await CommonService().fetchBasketCnt(context, showErrorMsg: false);
      }
    } catch (e, stackTrace) {
      debugPrint('[deleteBasketItems] Error: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<void> updateBasketItems({
    required List<Map<String, dynamic>> items,
    required BuildContext context,
  }) async {
    try {
      await _updateBasketItems(items: items);
      if (context.mounted) {
        await CommonService().fetchBasketCnt(context, showErrorMsg: false);
      }
    } catch (e, stackTrace) {
      debugPrint('[_addBasketItem] Error: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
}
