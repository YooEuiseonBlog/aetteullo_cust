// lib/service/address_service.dart

import 'package:aetteullo_cust/model/address_model.dart';
import 'package:aetteullo_cust/service/dio_service.dart';
import 'package:dio/dio.dart';

/// 자바 AddressController의 '/address' 엔드포인트와 통신하는 API 서비스 클래스
class AddressService {
  /// 도로명주소 검색
  ///
  /// [keyword]: 검색어 (빈 문자열이면 전체 조회 로직이 백엔드에서 처리)
  /// [currentPage]: 페이지 번호 (기본 1)
  /// [countPerPage]: 페이지당 건수 (기본 10)
  Future<Address> searchAddress({
    String keyword = '',
    int currentPage = 1,
    int countPerPage = 10,
    String resultType = 'json', // 백단 기본값이 json 이므로 고정
    String hstryYn = 'N',
    String firstSort = 'none',
    String addInfoYn = 'N',
  }) async {
    try {
      final resp = await DioCookieClient.http.get<Map<String, dynamic>>(
        '/address',
        queryParameters: {
          'keyword': keyword,
          'currentPage': currentPage,
          'countPerPage': countPerPage,
          'resultType': resultType,
          'hstryYn': hstryYn,
          'firstSort': firstSort,
          'addInfoYn': addInfoYn,
        },
      );

      final data = resp.data;
      if (data == null) {
        throw Exception('Empty response from /address');
      }

      // Flutter 모델로 파싱하여 반환
      return Address.fromJson(data);
    } on DioException catch (e) {
      throw Exception('주소 검색 실패: ${e.message}');
    }
  }
}
