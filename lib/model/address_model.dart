// lib/models/address_models.dart

class Address {
  final Common common;
  final List<Juso> juso;

  Address({required this.common, required this.juso});

  factory Address.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return Address(
      common: Common.fromJson(results['common'] as Map<String, dynamic>),
      juso: (results['juso'] as List<dynamic>)
          .map((e) => Juso.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Common {
  final int totalCount;
  final int currentPage;
  final int countPerPage;
  final String errorCode;
  final String errorMessage;

  Common({
    required this.totalCount,
    required this.currentPage,
    required this.countPerPage,
    required this.errorCode,
    required this.errorMessage,
  });

  factory Common.fromJson(Map<String, dynamic> json) => Common(
    totalCount: json['totalCount'] as int,
    currentPage: json['currentPage'] as int,
    countPerPage: json['countPerPage'] as int,
    errorCode: json['errorCode'] as String,
    errorMessage: json['errorMessage'] as String,
  );
}

class Juso {
  final String roadAddr;
  final String roadAddrPart1;
  final String roadAddrPart2;
  final String jibunAddr;
  final String engAddr;
  final String zipNo;
  final String admCd;
  final String rnMgtSn;
  final String bdMgtSn;
  final String detBdNmList;
  final String bdNm;
  final String bdKdcd;
  final String siNm;
  final String sggNm;
  final String emdNm;
  final String liNm;
  final String rn;
  final String udrtYn;
  final String buldMnnm;
  final String buldSlno;
  final String mtYn;
  final String lnbrMnnm;
  final String lnbrSlno;
  final String emdNo;

  Juso({
    required this.roadAddr,
    required this.roadAddrPart1,
    required this.roadAddrPart2,
    required this.jibunAddr,
    required this.engAddr,
    required this.zipNo,
    required this.admCd,
    required this.rnMgtSn,
    required this.bdMgtSn,
    required this.detBdNmList,
    required this.bdNm,
    required this.bdKdcd,
    required this.siNm,
    required this.sggNm,
    required this.emdNm,
    required this.liNm,
    required this.rn,
    required this.udrtYn,
    required this.buldMnnm,
    required this.buldSlno,
    required this.mtYn,
    required this.lnbrMnnm,
    required this.lnbrSlno,
    required this.emdNo,
  });

  factory Juso.fromJson(Map<String, dynamic> json) => Juso(
    roadAddr: json['roadAddr'] as String,
    roadAddrPart1: json['roadAddrPart1'] as String,
    roadAddrPart2: json['roadAddrPart2'] as String,
    jibunAddr: json['jibunAddr'] as String,
    engAddr: json['engAddr'] as String,
    zipNo: json['zipNo'] as String,
    admCd: json['admCd'] as String,
    rnMgtSn: json['rnMgtSn'] as String,
    bdMgtSn: json['bdMgtSn'] as String,
    detBdNmList: json['detBdNmList'] as String,
    bdNm: json['bdNm'] as String,
    bdKdcd: json['bdKdcd'] as String,
    siNm: json['siNm'] as String,
    sggNm: json['sggNm'] as String,
    emdNm: json['emdNm'] as String,
    liNm: json['liNm'] as String,
    rn: json['rn'] as String,
    udrtYn: json['udrtYn'] as String,
    buldMnnm: json['buldMnnm'] as String,
    buldSlno: json['buldSlno'] as String,
    mtYn: json['mtYn'] as String,
    lnbrMnnm: json['lnbrMnnm'] as String,
    lnbrSlno: json['lnbrSlno'] as String,
    emdNo: json['emdNo'] as String,
  );
}
