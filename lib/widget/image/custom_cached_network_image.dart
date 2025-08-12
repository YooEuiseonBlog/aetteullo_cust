import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 재사용 가능한 CachedNetworkImage 위젯
class CustomCachedNetworkImage extends StatelessWidget {
  final String? imageUrl; // 이미지 URL (nullable로 변경)
  final double width; // 이미지 너비
  final double height; // 이미지 높이
  final BoxFit fit; // 이미지 적합 방식
  final Widget? placeholder; // 로딩 중 표시할 위젯
  final Widget? errorWidget; // 에러 발생 시 표시할 위젯
  final BorderRadius? borderRadius; // 이미지의 경계 반경
  final Color? placeholderColor; // 플레이스홀더의 배경색
  final Color? errorColor; // 에러 위젯의 배경색

  /// 이미지 로드 실패 시 호출할 콜백
  final void Function(String url, dynamic error)? onError;

  const CustomCachedNetworkImage({
    super.key,
    this.imageUrl,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.placeholderColor,
    this.errorColor,
    this.onError, // 추가된 콜백 파라미터
  });

  @override
  Widget build(BuildContext context) {
    // imageUrl이 null이거나 빈 문자열인 경우 errorWidget을 표시
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: errorColor ?? Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(0),
        ),
        child:
            errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    // imageUrl이 유효한 경우 CachedNetworkImage를 사용
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(0),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: placeholderColor ?? Colors.grey[300],
          ),
          child: placeholder ?? const SizedBox.shrink(),
        ),
        errorWidget: (context, url, error) {
          // onError 콜백 호출
          if (onError != null) {
            onError!(url, error);
          }
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: errorColor ?? Colors.grey[300],
              borderRadius: borderRadius ?? BorderRadius.circular(0),
            ),
            child:
                errorWidget ??
                const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }
}
