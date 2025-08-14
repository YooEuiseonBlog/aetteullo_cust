import 'package:aetteullo_cust/screen/payment/payment_success_screen.dart';
import 'package:aetteullo_cust/widget/appbar/mobile_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen()),
        ModalRoute.withName('/payment'),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('결제가 실패하였습니다.')));
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

            // 팝업을 동일 WebView에서 열기 (WebChrome 규칙상 false 반환)
            onCreateWindow: (controller, action) async {
              controller.loadUrl(urlRequest: action.request);
              return false; // 새 WebView를 만들지 않음
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
