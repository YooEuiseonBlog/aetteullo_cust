import 'package:aetteullo_cust/function/format_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ItemCardV3 extends StatelessWidget {
  final String itemNm;
  final double price;
  final double qty;
  final String image;
  final String mnfct;
  final VoidCallback? onCheckoutPressed; // 구매하기 버튼
  final VoidCallback? onEditOptionsPressed; // 옵션/수량 변경 버튼

  const ItemCardV3({
    super.key,
    required this.itemNm,
    required this.price,
    required this.qty,
    this.image = '',
    this.mnfct = '-',
    this.onCheckoutPressed,
    this.onEditOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final totPrice = formatCurrency(price * qty);

    return Container(
      // ① 고정 높이 지정
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    width: 100,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (ctx, url, err) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ④ 텍스트 영역: Expanded로 남은 가로 채우기, 세로는 부모 높이에 맞춰짐
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // 위쪽 블록과 아래쪽 가격을 분산 배치
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              fontSize: 14,
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
                      Text(
                        '$totPrice원',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      // 하단 가격
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
