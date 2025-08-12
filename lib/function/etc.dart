String getLikeMessage(String itemNm, String like) {
  if (like == 'Y') {
    return '$itemNm은 관심품목에 추가되었습니다.';
  } else {
    return '$itemNm은 관심품목에서 제외되었습니다.';
  }
}
