import 'package:aetteullo_cust/service/common_service.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class OrderService {
  /// 주문 제출 (submit controller와 통신)
  Future<void> _submitOrder({
    required List<Map<String, dynamic>> items,
    required String zipCd,
    required String addr,
    required String addrDtl,
    required String memo,
    required DateTime deliRqstDate,
    String? cmnt,
  }) async {
    try {
      // 1) 요청 페이로드 구성
      final payload = {
        'items': items,
        'zipCd': zipCd,
        'addr': addr,
        'addrDtl': addrDtl,
        'memo': memo,
        if (cmnt != null && cmnt.isNotEmpty) 'cmnt': cmnt,
        // yyyy-MM-dd 형식으로 날짜 문자열 변환
        'deliRqstDate': DateFormat('yyyy-MM-dd').format(deliRqstDate),
      };
      // 2) submit API 호출
      await DioCookieClient.http.post('/mobile/order', data: payload);
    } on DioException catch (e) {
      debugPrint('submitPurchase Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('submitPurchase unexpected error: $e');
      rethrow;
    }
  }

  /// 주문 제출 (submit controller와 통신)
  Future<void> submitOrder({
    required List<Map<String, dynamic>> items,
    required String zipCd,
    required String addr,
    required String addrDtl,
    required String memo,
    required DateTime deliRqstDate,
    String? cmnt,
    required BuildContext context,
  }) async {
    try {
      await _submitOrder(
        items: items,
        zipCd: zipCd,
        addr: addr,
        addrDtl: addrDtl,
        memo: memo,
        deliRqstDate: deliRqstDate,
      );

      if (context.mounted) {
        await CommonService().fetchBasketCnt(context);
      }
    } on DioException catch (e) {
      debugPrint('submitPurchase Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('submitPurchase unexpected error: $e');
      rethrow;
    }
  }

  /// PO 헤더와 그에 속한 상세 항목(item 리스트)을 조회합니다.
  ///
  /// [poDate]가 주어지면 서버로 YYYY-MM-DD 포맷의 쿼리 파라미터로 전달합니다.
  /// null 이면 전체 PO 리스트를 조회합니다.
  Future<List<Map<String, dynamic>>> selectPoList({DateTime? poDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (poDate != null) {
        queryParams['poDate'] = DateFormat('yyyy-MM-dd').format(poDate);
      }
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/order',
        queryParameters: queryParams,
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('getPOList Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getPOList unexpected error: $e');
      rethrow;
    }
  }

  /// 취소(Po 상태 stat="1")된 PO 헤더와 상세를 조회합니다.
  /// [poDate], [clDate] 가 주어지면 각각 "yyyy-MM-dd" 포맷으로 쿼리에 포함합니다.
  /// null 이면 해당 파라미터 없이 전체 조회합니다.
  Future<List<Map<String, dynamic>>> getCancelPoList({DateTime? clDate}) async {
    try {
      // 쿼리 파라미터 준비
      final queryParams = <String, dynamic>{};

      if (clDate != null) {
        queryParams['clDate'] = DateFormat('yyyy-MM-dd').format(clDate);
      }

      // GET /mobile/order/cancel?poDate=2025-05-26&clDate=2025-05-25
      final resp = await DioCookieClient.http.get<List<dynamic>>(
        '/mobile/order/cancel',
        queryParameters: queryParams,
      );

      return (resp.data ?? []).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      debugPrint('getCancelPOList Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getCancelPOList unexpected error: $e');
      rethrow;
    }
  }

  /// 주문 취소
  Future<void> submitCancel({
    required String poNo,
    required String memo,
  }) async {
    try {
      // DELETE /mobile/order/{poNo}?memo={memo}
      await DioCookieClient.http.delete(
        '/mobile/order/$poNo',
        queryParameters: {'memo': memo},
      );
    } on DioException catch (e) {
      debugPrint('submitCancel Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('submitCancel unexpected error: $e');
      rethrow;
    }
  }

  /// 주문 취소
  Future<void> submitRtn({
    required List<Map<String, dynamic>> items,
    required String rtnMemo,
  }) async {
    try {
      // DELETE /mobile/order/{poNo}?memo={memo}
      await DioCookieClient.http.post('/mobile/rtn');
    } on DioException catch (e) {
      debugPrint('submitCancel Dio error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('submitCancel unexpected error: $e');
      rethrow;
    }
  }
}
