import 'package:flutter/material.dart';

Color getPoStatusColor(String stat) {
  switch (stat) {
    // 접수 대기
    case '0':
      return Colors.grey;

    // 접수 확정
    case '1':
      return Colors.blue;

    // 출고 요청, 배송 준비, 배송중 → 진행 중
    case '2': // 출고 요청
    case '3': // 배송 준비
    case '4': // 배송중
      return Colors.orange;

    // 배송 완료, 거래 완료 → 완료
    case '5': // 배송 완료
    case '7': // 거래 완료
      return Colors.green;

    // 부분 입고
    case '6':
      return Colors.lightGreen;

    // 발주 취소, 발주 거절 → 에러/취소
    case '8': // 발주 취소
    case '9': // 발주 거절
      return Colors.red;

    // 그 외
    default:
      return Colors.black;
  }
}

Color getDeliStatColor(String stat) {
  switch (stat) {
    // 코드 0,1: 배송 접수 단계 (블루)
    case '0':
    case '1':
      return Colors.blue.shade500;
    // 코드 2: 배송 중 단계 (앰버/오렌지)
    case '2':
      return Colors.amber.shade600;
    // 코드 3: 배송 완료 단계 (그린)
    case '3':
      return Colors.green.shade600;
    // 그 외: 회색으로 표시
    default:
      return Colors.grey;
  }
}
