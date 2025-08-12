import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String?> getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    // Android의 고유 ID: androidId
    return androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    // iOS의 고유 ID: identifierForVendor
    return iosInfo.identifierForVendor;
  } else {
    // 지원하지 않는 플랫폼인 경우 null 반환
    return null;
  }
}
