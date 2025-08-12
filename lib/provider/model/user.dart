class User {
  final int? userId;
  final String loginId;
  final String userNm;
  final String phone;
  final String email;
  final String industCd;
  final String industNm;
  final String ownerNm;
  final String bizType;
  final String bizKind;
  final String zipCd;
  final String addr;
  final String addrDtl;
  final int? gradeCd;
  final String gradeNm;
  final String userDiv;
  final String userDivNm;

  User({
    required this.userId,
    required this.loginId,
    required this.userNm,
    required this.phone,
    required this.email,
    required this.industCd,
    required this.industNm,
    required this.ownerNm,
    required this.bizType,
    required this.bizKind,
    required this.zipCd,
    required this.addr,
    required this.addrDtl,
    required this.gradeCd,
    required this.gradeNm,
    required this.userDiv,
    required this.userDivNm,
  });

  User.empty()
    : userId = null,
      loginId = '',
      userNm = '',
      phone = '',
      email = '',
      industCd = '',
      industNm = '',
      ownerNm = '',
      bizType = '',
      bizKind = '',
      zipCd = '',
      addr = '',
      addrDtl = '',
      gradeCd = null,
      gradeNm = '',
      userDiv = '',
      userDivNm = '';

  bool get isEmpty => loginId.isEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return User(
      userId: json['userId'] as int?,
      loginId: s(json['loginId']),
      userNm: s(json['userNm']),
      phone: s(json['phone']),
      email: s(json['email']),
      industCd: s(json['industCd']),
      industNm: s(json['industNm']),
      ownerNm: s(json['ownerNm']),
      bizType: s(json['bizType']),
      bizKind: s(json['bizKind']),
      zipCd: s(json['zipCd']),
      addr: s(json['addr']),
      addrDtl: s(json['addrDtl']),
      gradeCd: json['gradeCd'] as int?,
      gradeNm: s(json['gradeNm']),
      userDiv: s(json['userDiv']),
      userDivNm: s(json['userDivNm']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'loginId': loginId,
    'userNm': userNm,
    'phone': phone,
    'email': email,
    'industCd': industCd,
    'industNm': industNm,
    'ownerNm': ownerNm,
    'bizType': bizType,
    'bizKind': bizKind,
    'zipCd': zipCd,
    'addr': addr,
    'addrDtl': addrDtl,
    'gradeCd': gradeCd,
    'gradeNm': gradeNm,
    'userDiv': userDiv,
    'userDivNm': userDivNm,
  };
}
