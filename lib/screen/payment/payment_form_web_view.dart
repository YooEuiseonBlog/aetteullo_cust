import 'package:aetteullo_cust/screen/payment/payment_success_screen.dart';
import 'package:aetteullo_cust/screen/payment/payment_vbank_success_screen.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentFormWebView extends StatefulWidget {
  final String url; // ex) https://192.168.0.13:8080/api/...
  final String? bearerToken; // JWT 문자열

  const PaymentFormWebView({super.key, required this.url, this.bearerToken});

  @override
  State<PaymentFormWebView> createState() => _PaymentFormWebViewState();
}

class _PaymentFormWebViewState extends State<PaymentFormWebView> {
  InAppWebViewController? _controller;
  bool _loading = true;
  String? _finalUrl;

  static const _bridgeName = 'onPaymentFinished';

  @override
  void initState() {
    super.initState();
    debugPrint('url: ${widget.url}');
    debugPrint('token: ${widget.bearerToken}');
  }

  @override
  void dispose() {
    try {
      _controller?.stopLoading();
      _controller?.pauseAllMediaPlayback();
      _controller?.pauseTimers();
      _controller?.clearFocus();
      _controller = null; // dispose()는 불필요
    } catch (_) {}
    super.dispose();
  }

  // URL로부터 쿠키 도메인(origin) 구성 (scheme://host[:port])
  WebUri _originFrom(String raw) {
    final u = WebUri(raw);
    final hasPort = u.port != 0;
    return WebUri('${u.scheme}://${u.host}${hasPort ? ':${u.port}' : ''}');
  }

  void _handlePaymentFinished(Map<String, dynamic> payload) {
    if (kDebugMode) debugPrint('📩 Payment Finished: $payload');

    final success = payload['success'] == true;
    final paySe = payload['paySe'];

    if (success) {
      if (paySe == 'vbank') {
        final bankNm = payload['bankNm'] as String? ?? '';
        final vactNo = payload['vactNo'] as String? ?? '';
        final holder = payload['holder'] as String? ?? '';
        final exprDt = payload['exprDt'] as String? ?? '';
        final amount = payload['amount'] as int? ?? 0;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentVBankSuccessScreen(
              bankNm: bankNm,
              vactNo: vactNo,
              holder: holder,
              amount: amount,
              exprDt: exprDt,
            ),
          ),
          ModalRoute.withName('/payment'),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => PaymentSuccessScreen()),
          ModalRoute.withName('/payment'),
        );
      }
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('결제가 실패하였습니다.')));
    }
  }

  // ───────────────────────────────────────────────────────────
  // 🔸 intent:// 에서 package= 추출
  String? extractPackageName(String url) {
    final m = RegExp(r'package=([^;]+)').firstMatch(url);
    return m?.group(1);
  }

  // 🔸 intent:// 에서 fallback url 추출
  String? extractFallbackUrl(String url) {
    final m = RegExp(r'S\.browser_fallback_url=([^;]+)').firstMatch(url);
    return m?.group(1);
  }

  String? _guessPackageFromScheme(String scheme) {
    switch (scheme) {
      // 카카오/토스/페이코/LPAY/SSGPAY
      case 'kakaotalk':
        return 'com.kakao.talk';
      case 'kakaopay':
        return 'com.kakaopay.app';
      case 'supertoss': // 일부 iOS-style 스킴이 들어올 수 있어 키워드로만 사용
      case 'toss':
        return 'viva.republica.toss';
      case 'payco':
        return 'com.nhnent.payapp';
      case 'lpayapp':
      case 'lmslpay':
        return 'com.lottemembers.android';
      case 'shinsegaeeasypayment':
        return 'com.ssg.serviceapp.android.egiftcertificate'; // 확인 필요

      // 카드사 계열 (iOS 스킴 → 안드로이드 패키지 추정)
      case 'kb-acp':
      case 'kbbank':
      case 'liivbank':
      case 'newliiv':
        return 'com.kbcard.cxh.appcard'; // KBPay로 우선 유도
      case 'shinhan-sr-ansimclick':
      case 'shc-ansimclick':
      case 'smshinhanansimclick':
        return 'com.shcard.smartpay';
      case 'hdcardappcardansimclick':
      case 'smhyundaiansimclick':
        return 'com.hyundaicard.appcard';
      case 'mpocket.online.ansimclick':
      case 'monimopay':
      case 'monimopayauth':
      case 'scardcertiapp':
        return 'kr.co.samsungcard.mpocket';
      case 'cloudpay':
      case 'hanawalletmembers':
      case 'hanaskcardmobileportal':
        return 'com.hanaskcard.paycla';
      case 'nhallonepayansimclick':
      case 'nonghyupcardansimclick':
        return 'nh.smart.nhallonepay'; // 확인 필요
      case 'citimobileapp':
        return 'kr.co.citibank.citimobile';
      case 'wooripay':
      case 'newsmtpib':
      case 'com.wooricard.wcard':
        return 'com.wooricard.smartapp';

      // ISP/공통
      case 'ispmobile':
        return 'kvp.jjy.MispAndroid320';

      // 은행/뱅크페이
      case 'kftc-bankpay':
        return 'com.kftc.bankpay.android';
      case 'kakaobank':
        return 'com.kakaobank.channel';
      case 'ukbanksmartbanknonloginpay':
        return 'com.kbankwith.smartbank';

      // 기타
      case 'tmoneypay':
        return 'com.tmoney.tmpay';
      case 'chai':
        return 'finance.chai.app';
      case 'alipay':
        return 'com.eg.android.AlipayGphone';
      case 'weixin':
      case 'wechat':
        return 'com.tencent.mm';

      default:
        return null;
    }
  }

  // 🔸 마켓 이동(패키지 없으면 검색)
  Future<void> _openPlayStore({String? package, String? keyword}) async {
    Uri uri;
    if (package != null && package.isNotEmpty) {
      uri = Uri.parse('market://details?id=$package');
    } else if (keyword != null && keyword.isNotEmpty) {
      uri = Uri.parse('market://search?q=${Uri.encodeComponent(keyword)}');
    } else {
      // 최후: 플레이스토어 홈
      uri = Uri.parse('market://details?id=com.android.vending');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // 🔸 커스텀 스킴/인텐트 처리
  Future<void> _openExternal(Uri uri) async {
    final s = uri.toString();

    // ───────────────── intent:// 처리 ─────────────────
    if (s.startsWith('intent://')) {
      final pkg = extractPackageName(s); // package=...
      final fallback = extractFallbackUrl(s); // S.browser_fallback_url=...

      // 1) Android 인텐트 직접 실행 시도 (intent:)
      final intentUri = Uri.parse(s.replaceFirst('intent://', 'intent:'));
      if (await canLaunchUrl(intentUri)) {
        await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        return;
      }

      // ✅ 2) 인텐트 실패 시: scheme + data 로 "실제 딥링크" 재시도
      //    예: scheme=shinhan-sr-ansimclick, data=pay?srCode=...
      final scheme = RegExp(r'scheme=([^;]+)').firstMatch(s)?.group(1);
      final data = RegExp(
        r'intent://([^#]+)#',
      ).firstMatch(s)?.group(1); // pay?...

      if (scheme != null && data != null) {
        final deepLink = Uri.parse(
          '$scheme://$data',
        ); // shinhan-sr-ansimclick://pay?...
        if (await canLaunchUrl(deepLink)) {
          await launchUrl(deepLink, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // 3) fallback url 존재 시
      if (fallback != null) {
        final fb = Uri.parse(Uri.decodeFull(fallback));
        if (await canLaunchUrl(fb)) {
          await launchUrl(fb, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // 4) 마켓 이동
      if (pkg != null) {
        await _openPlayStore(package: pkg);
      } else {
        await _openPlayStore(keyword: scheme ?? uri.scheme);
      }
      return;
    }
    // ───────────────── intent:// 처리 끝 ─────────────────

    // 커스텀 스킴(ex. mvaccine:// 등)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    // 실행 불가 → 스킴으로 패키지 추정 후 마켓 이동
    final guess = _guessPackageFromScheme(uri.scheme);
    if (guess != null) {
      await _openPlayStore(package: guess);
    } else {
      await _openPlayStore(keyword: uri.scheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppBar(
        title: '결제',
        showBasket: false,
        showSearch: false,
        showNotification: false,
      ),
      body: Stack(
        children: [
          InAppWebView(
            // ❷ 첫 로드는 onWebViewCreated에서 쿠키 심은 뒤 loadUrl로 수행
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true,
              supportMultipleWindows: true,
            ),

            // ✅ http/https만 WebView로, 나머지는 외부 처리
            shouldOverrideUrlLoading: (controller, action) async {
              final uri = action.request.url;
              if (uri == null) return NavigationActionPolicy.CANCEL;

              // intent: // 들어오면 package= 로깅
              // final urlStr = uri.toString();
              // if (urlStr.startsWith('intent://')) {
              //   final pkg = extractPackageName(urlStr);
              //   final msg = 'URL: $urlStr\n패키지: ${pkg ?? "(없음)"}';

              //   // 1) 콘솔에도 찍기
              //   debugPrint('🧩 $msg');

              //   // 2) 화면에 Alert로 띄우기
              //   WidgetsBinding.instance.addPostFrameCallback((_) {
              //     showDialog(
              //       context: context,
              //       builder: (_) => AlertDialog(
              //         title: const Text('Intent URL Detected'),
              //         content: SingleChildScrollView(child: Text(msg)),
              //         actions: [
              //           TextButton(
              //             onPressed: () => Navigator.pop(context),
              //             child: const Text('OK'),
              //           ),
              //         ],
              //       ),
              //     );
              //   });
              // }

              const inApp = {
                'http',
                'https',
                'about',
                'data',
                'file',
                'javascript',
              };
              if (inApp.contains(uri.scheme)) {
                return NavigationActionPolicy.ALLOW;
              }

              await _openExternal(uri);
              return NavigationActionPolicy.CANCEL;
            },

            onWebViewCreated: (c) async {
              _controller = c;

              // ❶ JWT 쿠키 세팅 (필터가 JWT_TOKEN 쿠키를 읽음)
              final token = widget.bearerToken;
              if (token != null && token.isNotEmpty) {
                await CookieManager.instance().setCookie(
                  url: _originFrom(widget.url),
                  name: 'JWT_TOKEN',
                  value: token,
                  isHttpOnly: true,
                  sameSite: HTTPCookieSameSitePolicy.LAX,
                  path: '/',
                );
              }

              // 브릿지 등록 (JS -> Flutter)
              _controller?.addJavaScriptHandler(
                handlerName: _bridgeName,
                callback: (args) async {
                  if (args.isNotEmpty && args.first is Map) {
                    _handlePaymentFinished(
                      Map<String, dynamic>.from(args.first),
                    );
                  }

                  return {'ack': true};
                },
              );

              // 쿠키 세팅 후 최초 로드 (원하면 Authorization 헤더도 추가 가능)
              await _controller?.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(widget.url),
                  // headers: {'Authorization': 'Bearer $token'}, // 필요 시
                ),
              );
            },

            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              return ServerTrustAuthResponse(
                action: kReleaseMode
                    ? ServerTrustAuthResponseAction.CANCEL
                    : ServerTrustAuthResponseAction.PROCEED,
              );
            },

            // ✅ 새 창 요청도 동일 정책 적용
            onCreateWindow: (controller, action) async {
              final uri = action.request.url;
              if (uri != null) {
                const inApp = {
                  'http',
                  'https',
                  'about',
                  'data',
                  'file',
                  'javascript',
                };
                if (inApp.contains(uri.scheme)) {
                  controller.loadUrl(urlRequest: action.request);
                } else {
                  await _openExternal(uri);
                }
              }
              return false; // 새 WebView 만들지 않음
            },

            onLoadStart: (controller, url) {
              if (kDebugMode) debugPrint('➡️ start: $url');
              setState(() => _loading = true);
            },
            onLoadStop: (controller, url) async {
              _finalUrl = url?.toString();
              if (kDebugMode) {
                debugPrint('🔚 FINAL URL: $_finalUrl');
                final current = await controller.getUrl();
                debugPrint('🌐 controller.getUrl(): ${current?.toString()}');
              }
              setState(() => _loading = false);
            },
            onReceivedError: (controller, request, error) {
              if (kDebugMode) {
                debugPrint('❌ WebView error: ${error.description}');
              }
              setState(() => _loading = false);
            },
          ),

          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
