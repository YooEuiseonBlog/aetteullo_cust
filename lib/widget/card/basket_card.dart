import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BasketCard extends StatelessWidget {
  final bool isChecked;
  final String itemNm;
  final double price;
  final double originalPrice;
  final double rate;
  final double qty;
  final String image;
  final String mnfct;
  final String promoYn;
  final VoidCallback? onCheckoutPressed; // 구매하기 버튼
  final VoidCallback? onEditOptionsPressed; // 옵션/수량 변경 버튼
  final ValueChanged<bool?>? onCheckedChanged; // 체크박스 상태 변경
  final VoidCallback? onClosePressed; // 닫기(✕) 버튼
  final VoidCallback? onImageTap; // 이미지 클릭 콜백 추가

  const BasketCard({
    super.key,
    this.isChecked = false,
    required this.price,
    required this.qty,
    this.image = '',
    required this.itemNm,
    this.mnfct = '-',
    this.onCheckedChanged,
    this.onClosePressed,
    this.onCheckoutPressed,
    this.onEditOptionsPressed,
    this.onImageTap,
    required this.originalPrice,
    required this.promoYn,
    required this.rate, // 생성자에 포함
  });

  @override
  Widget build(BuildContext context) {
    final totPrice = formatCurrency(price * qty);

    return Stack(
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IntrinsicHeight로 상단 Row 높이 맞추기
              Expanded(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 체크박스를 상단에만 위치
                      Align(
                        alignment: Alignment.topCenter,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: Colors.green,
                          onChanged: onCheckedChanged,
                          visualDensity: const VisualDensity(vertical: -4),
                        ),
                      ),
                      const SizedBox(width: 5),

                      // 이미지 (클릭 시 onImageTap 호출)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: onImageTap,
                          child: CachedNetworkImage(
                            imageUrl: image,
                            width: 100,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (ctx, url, err) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 텍스트 영역
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단 정보
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemNm,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  mnfct,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '수량: ${qty.toInt()}개',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),

                            // 하단 가격
                            if (promoYn == 'Y') ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${formatCurrency(originalPrice * qty)}원',
                                        style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${(rate).toInt()}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$totPrice원',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Text(
                                '$totPrice원',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 옵션/구매 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: onEditOptionsPressed,
                        child: const Text('옵션/수량변경'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      fit: FlexFit.tight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onCheckoutPressed,
                        child: const Text('구매하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 우측 상단 X 버튼
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onClosePressed,
            behavior: HitTestBehavior.translucent,
            child: const Icon(Icons.close, size: 20, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
