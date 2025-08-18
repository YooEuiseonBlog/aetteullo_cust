import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final String? title;
  final double? amount;
  final String? stat;
  final String? statNm;
  final String? date;
  final String? subDate;
  final String? receiver;
  final String? image;
  final Color? color;
  final double? cnt;
  final List<String>? options;
  final VoidCallback? onClickDtlBtn;
  final bool isRtn;
  final bool isCncl;
  final EdgeInsetsGeometry? margin;
  const OrderCard({
    super.key,
    this.title,
    this.amount,
    this.stat,
    this.statNm,
    this.date,
    this.receiver,
    this.image,
    this.cnt,
    this.options,
    this.onClickDtlBtn,
    this.color,
    this.isRtn = false,
    this.isCncl = false,
    this.margin,
    this.subDate,
  });

  @override
  Widget build(BuildContext context) {
    Color pColor = color ?? Colors.green;
    final formattedAmount = formatCurrency(amount ?? 0);

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onClickDtlBtn,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isRtn
                          ? '반품상세'
                          : isCncl
                          ? "취소상세"
                          : '주문상세',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isRtn)
            if (subDate != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('주문일', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    subDate ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: pColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stat ?? '',
              style: TextStyle(fontWeight: FontWeight.bold, color: pColor),
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1) 썸네일
                ClipRRect(
                  borderRadius: BorderRadius.circular(8), // 모서리 반경
                  child: CachedNetworkImage(
                    imageUrl: image ?? '',
                    width: 100, // 원하는 썸네일 가로 크기
                    height: 100, // 원하는 썸네일 세로 크기
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 100, // 원하는 썸네일 가로 크기
                      height: 120, // 원하는 썸네일 세로 크기
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 100, // 원하는 썸네일 가로 크기
                      height: 120, // 원하는 썸네일 세로 크기
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '종류: ${(cnt ?? 0).toInt()}개',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$formattedAmount원',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
