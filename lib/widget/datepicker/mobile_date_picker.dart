import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class MobileDatePicker extends StatefulWidget {
  final TextEditingController controller;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String hintText;
  final InputDecoration? decoration;
  final bool readOnly; // readOnly 속성 추가
  final void Function(DateTime? selectedDate)? onChanged; // 날짜 변경 콜백 추가

  MobileDatePicker({
    super.key,
    required this.controller,
    this.initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    this.hintText = '날짜 선택',
    this.decoration,
    this.readOnly = false, // 기본값 false
    this.onChanged, // 날짜 변경 콜백
  }) : firstDate = firstDate ?? DateTime(2000),
       lastDate = lastDate ?? DateTime(2100);

  @override
  State<MobileDatePicker> createState() => _MobileDatePickerState();
}

class _MobileDatePickerState extends State<MobileDatePicker> {
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // 컨트롤러 값이 바뀔 때마다 리빌드를 하도록 리스너 추가
    widget.controller.addListener(() {
      setState(() {});
    });
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
      widget.controller.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else {
      _selectedDate = null;
      widget.controller.text = ''; // 초기값이 없을 때 빈 문자열
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Colors.green, // 헤더 색상
              onPrimary: Colors.white, // 헤더 텍스트 색상
              onSurface: Colors.black, // 날짜 텍스트 색상
            ), // 다이얼로그 배경 색상
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green, // 선택 버튼 색상
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        widget.controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      // onChanged 콜백 호출
      if (widget.onChanged != null) {
        widget.onChanged!(picked);
      }
    }
  }

  /// 리프레시 버튼과 달력 아이콘을 함께 보여주는 suffixIcon 위젯
  /// - controller.text에 내용이 있을 때만 리프레시 버튼(IconButton)을 표시하고,
  /// - 내용이 없으면 같은 너비의 SizedBox를 배치하여 전체 넓이가 일정하게 유지되도록 함.
  /// - 그리고 전체 아이콘들을 Padding으로 감싸서 내부 여백을 줍니다.
  Widget _buildSuffixIcon() {
    Widget refreshIcon;
    if (widget.controller.text.isNotEmpty) {
      refreshIcon = IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          // 리프레시 버튼 클릭 시: 선택된 날짜를 초기화하고 컨트롤러를 비웁니다.
          setState(() {
            _selectedDate = null;
            widget.controller.clear();
          });
          if (widget.onChanged != null) {
            widget.onChanged!(null);
          }
        },
      );
    } else {
      // IconButton 대신에 일정 너비를 가진 빈 공간을 사용하여 레이아웃 유지를 보장합니다.
      refreshIcon = const SizedBox(width: 48);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
      ), // 아이콘들이 안쪽으로 들어오도록 여백을 추가
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [refreshIcon, const Icon(Icons.calendar_today)],
      ),
    );
  }

  InputDecoration basicInputDecoration() {
    return InputDecoration(
      hintText: widget.hintText,
      suffixIcon: _buildSuffixIcon(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      // ↓ 언더라인 제거를 위한 설정
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }

  InputDecoration _mergeDecorations({
    required InputDecoration base,
    InputDecoration? custom,
  }) {
    if (custom == null) {
      return base;
    }
    return base.copyWith(
      hintText: custom.hintText ?? base.hintText,
      labelText: custom.labelText ?? base.labelText,
      prefixIcon: custom.prefixIcon ?? base.prefixIcon,
      // suffixIcon은 항상 _buildSuffixIcon()의 결과를 사용합니다.
      suffixIcon: _buildSuffixIcon(),
      contentPadding: custom.contentPadding ?? base.contentPadding,
      fillColor: custom.fillColor ?? base.fillColor,
      filled: custom.filled ?? base.filled,
      border: custom.border ?? base.border,
      enabledBorder: custom.enabledBorder ?? base.enabledBorder,
      focusedBorder: custom.focusedBorder ?? base.focusedBorder,
      hintStyle: custom.hintStyle ?? base.hintStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      readOnly: true,
      enabled: !widget.readOnly,
      // TextField 자체의 onTap을 사용하여 달력이 열리도록 처리합니다.
      onTap: widget.readOnly ? null : () => _selectDate(context),
      decoration: _mergeDecorations(
        base: basicInputDecoration(),
        custom: widget.decoration,
      ),
    );
  }
}
