import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 전화번호 자동 포맷터: 숫자만 입력받아 즉시 포맷팅 (예: 01012345678 → "010-1234-5678")
class PhoneNumberFormatter extends TextInputFormatter {
  static const maxLength = 11; // 최대 11자리

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > maxLength) {
      return oldValue;
    }

    String formatted = digitsOnly;
    if (digitsOnly.length >= 4 && digitsOnly.length < 8) {
      formatted = '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
    } else if (digitsOnly.length >= 8) {
      formatted =
          '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// "YYY-ZZZZZZZC-XXX" 형식으로 14자리 계좌번호를 포맷팅하는 TextInputFormatter
/// - YYY: 첫 3자리
/// - ZZZZZZZ: 다음 7자리
/// - C: 1자리
/// - XXX: 마지막 3자리
class AccountNumberFormatter extends TextInputFormatter {
  static const int maxDigits = 14;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 입력값에서 숫자만 추출
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 최대 14자리까지만 허용
    if (digitsOnly.length > maxDigits) {
      digitsOnly = digitsOnly.substring(0, maxDigits);
    }

    String formatted = '';
    int length = digitsOnly.length;

    if (length <= 3) {
      // 첫번째 그룹: 최대 3자리
      formatted = digitsOnly;
    } else if (length <= 10) {
      // 첫 3자리, dash, 그리고 나머지 (최대 7자리)
      formatted = '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
    } else {
      // 첫 3자리, dash, 다음 7자리, dash, 그리고 나머지 (최대 3자리)
      formatted =
          '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 10)}-${digitsOnly.substring(10)}';
    }

    // 커서 위치를 마지막으로 이동
    int selectionIndex = formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

/// 숫자 입력에만 허용하고, 천 단위로 콤마 찍어줌
class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat.decimalPattern(); // 기본 로케일에 맞춰 , 찍음

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 기존 콤마 제거
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    // 숫자로 파싱
    final intValue = int.parse(digits);
    // 포맷 적용
    final newText = _fmt.format(intValue);
    // 캐럿(커서) 위치를 텍스트 끝으로 이동
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// YYYY-MM-DD 형식으로 자동 포맷팅해주는 TextInputFormatter
/// - 숫자만 입력받아 즉시 포맷팅 (예: 20250630 → "2025-06-30")
class DateInputFormatter extends TextInputFormatter {
  static const int maxDigits = 8; // YYYYMMDD

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 남기기
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // 최대 8자리까지만
    final truncated = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      buffer.write(truncated[i]);
      // 4번째, 6번째 자리 뒤에 하이픈 추가
      if (i == 3 || i == 5) buffer.write('-');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 숫자 입력 시 최대값(max)을 넘으면 max로 고정해 주는 Formatter
class MaxValueFormatter extends TextInputFormatter {
  final int max;
  MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 비어있거나 숫자가 아니면 그대로
    if (newValue.text.isEmpty) return newValue;
    final int? value = int.tryParse(
      newValue.text.replaceAll(RegExp(r'[^\d]'), ''),
    );
    if (value == null) return oldValue;

    // max 초과 시 max로 교체
    if (value > max) {
      final newText = max.toString();
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    return newValue;
  }
}
