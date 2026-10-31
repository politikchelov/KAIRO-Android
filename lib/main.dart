import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF101114),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF101114),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const KairoApp());
}

class KairoApp extends StatelessWidget {
  const KairoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAIRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101114),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE9B66B),
          surface: Color(0xFF101114),
        ),
        useMaterial3: true,
      ),
      home: const KairoHome(),
    );
  }
}

class KairoHome extends StatefulWidget {
  const KairoHome({super.key});

  @override
  State<KairoHome> createState() => _KairoHomeState();
}

class _KairoHomeState extends State<KairoHome> {
  static final Uri _home = Uri.parse('https://kaironet.vercel.app/');
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF101114))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() {
              _hasError = false;
              _progress = 0;
            });
          },
          onPageFinished: (_) async {
            final back = await _controller.canGoBack();
            if (mounted) setState(() {
              _progress = 100;
              _canGoBack = back;
            });
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _hasError = true);
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'https' || uri.scheme == 'http') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_home);
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF101114),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF26272B), width: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'KAIRO',
                      style: TextStyle(
                        color: Color(0xFFF4F0E8),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Обновить',
                      onPressed: () => _controller.reload(),
                      icon: const Icon(Icons.refresh_rounded, size: 22),
                    ),
                  ],
                ),
              ),
              if (_progress < 100)
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 2,
                  backgroundColor: const Color(0xFF202126),
                  color: const Color(0xFFE9B66B),
                )
              else
                const SizedBox(height: 2),
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_hasError)
                      Positioned.fill(
                        child: ColoredBox(
                          color: const Color(0xFF101114),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_rounded,
                                      size: 42, color: Color(0xFFE9B66B)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Не удалось загрузить KAIRO',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Проверь подключение к интернету и попробуй ещё раз.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF9B9BA1),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton(
                                    onPressed: () {
                                      setState(() => _hasError = false);
                                      _controller.loadRequest(_home);
                                    },
                                    child: const Text('Повторить'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
