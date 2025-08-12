import 'package:intl/intl.dart';

/// 전화번호 문자열을 '010-1234-5678' 형태로 포맷
String formatPhone(String phone) {
  final reg = RegExp(r'^(\d{2,3})(\d{3,4})(\d{4})\$');
  final match = reg.firstMatch(phone);
  if (match != null) {
    return '\${match[1]}-\${match[2]}-\${match[3]}';
  }
  return phone.isNotEmpty ? phone : '-';
}

String formatTime4(String time4) {
  // 1) 끝에 \$ 삭제하고 '$' 앵커로 사용
  final reg = RegExp(r'^(\d{2})(\d{2})$');
  final match = reg.firstMatch(time4);

  if (match != null) {
    // 2) 문자열 보간은 '\$' 없이
    final h = match.group(1);
    final m = match.group(2);
    return '$h:$m';
  }
  // 매치 안 되면 '-' 또는 원본
  return time4.isNotEmpty ? time4 : '-';
}

/// num 타입 금액을 "1,234,567" 형태로 포맷
String formatCurrency(num amount) {
  final formatter = NumberFormat.decimalPattern('ko_KR');
  return formatter.format(amount);
}

/// 문자열 금액을 파싱 후 포맷. 파싱 실패 시 원본 반환
String formatCurrencyFromString(String amountStr) {
  try {
    final value = num.parse(amountStr);
    return formatCurrency(value);
  } catch (_) {
    return amountStr;
  }
}

/// 주어진 DateTime 또는 현재 시각을 "yyyyMMdd" 형태의 문자열로 반환합니다.
String toYyyyMMdd([DateTime? date]) {
  final dt = date ?? DateTime.now();
  return DateFormat('yyyyMMdd').format(dt);
}

/// "yyyyMMdd" 문자열을 구분자(sep)로 "yyyy{sep}MM{sep}dd"로 포맷
String formatYyyyMMdd(String ymd, String sep) {
  if (ymd.length != 8) return ymd;
  final y = ymd.substring(0, 4);
  final m = ymd.substring(4, 6);
  final d = ymd.substring(6, 8);
  return [y, m, d].join(sep);
}

/// "yyyyMMdd" 문자열을 DateTime으로 변환. 파싱 실패 시 null 반환
DateTime? parseYyyyMMdd(String? ymd) {
  if (ymd == null || ymd.length != 8) return null;
  final y = int.tryParse(ymd.substring(0, 4));
  final m = int.tryParse(ymd.substring(4, 6));
  final d = int.tryParse(ymd.substring(6, 8));
  if (y != null && m != null && d != null) {
    return DateTime(y, m, d);
  }
  return null;
}

/// null 또는 빈 문자열인 경우 '-' 반환, alt 주어지면 alt, 아니면 value.toString()
String getOrHyphen(Object? value, [Object? alt]) {
  if (value == null) return '-';
  if (value is String && value.isEmpty) return '-';
  if (alt != null) {
    return alt.toString();
  }
  return value.toString();
}
