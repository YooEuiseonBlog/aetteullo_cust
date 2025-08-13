import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 네이버 테스트용 WebView 스크린
class NaverWebViewTestScreen extends StatefulWidget {
  static const routeName = '/test/naver-webview';

  const NaverWebViewTestScreen({super.key});

  @override
  State<NaverWebViewTestScreen> createState() => _NaverWebViewTestScreenState();
}

class _NaverWebViewTestScreenState extends State<NaverWebViewTestScreen> {
  InAppWebViewController? _controller;
  bool _loading = true;
  String? _finalUrl;

  @override
  void initState() {
    super.initState();
    debugPrint('NaverWebViewTestScreen init');
  }

  @override
  void dispose() {
    try {
      _controller?.stopLoading();
      _controller?.pauseAllMediaPlayback();
      _controller?.pauseTimers();
      _controller?.clearFocus();
      _controller?.dispose();
    } catch (_) {}
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('네이버 WebView 테스트')),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://m.naver.com'), // 또는 https://www.naver.com
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true, // window.open 허용
              supportMultipleWindows: true, // 팝업 콜백 받기
              // userAgent: '...', // 필요 시 커스텀 UA
            ),
            onWebViewCreated: (c) => _controller = c,

            // 팝업창 열기 요청이 오면 같은 WebView에서 열도록 처리
            onCreateWindow: (controller, action) async {
              controller.loadUrl(urlRequest: action.request);
              return true;
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
            },

            // ※ 개발용 자체서명/사설 인증서 환경에서만 임시 허용 (운영 금지)
            // onReceivedServerTrustAuthRequest: (controller, challenge) async {
            //   return ServerTrustAuthResponse(
            //     action: kReleaseMode
            //         ? ServerTrustAuthResponseAction.CANCEL
            //         : ServerTrustAuthResponseAction.PROCEED,
            //   );
            // },

            // 외부 앱 스킴(전화/이메일 등)을 처리하려면 여기서 가로채기
            // shouldOverrideUrlLoading: (controller, navAction) async {
            //   final uri = navAction.request.url;
            //   if (uri != null && (uri.scheme == 'tel' || uri.scheme == 'mailto')) {
            //     // launchUrl(uri); // url_launcher로 처리 (필요시)
            //     return NavigationActionPolicy.CANCEL;
            //   }
            //   return NavigationActionPolicy.ALLOW;
            // },
          ),

          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
