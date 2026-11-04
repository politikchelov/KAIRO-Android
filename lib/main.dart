import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _bg = Color(0xFF090611);
const _purple = Color(0xFF8B20F5);
const _pink = Color(0xFFE34BFF);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _bg,
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
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _purple,
          brightness: Brightness.dark,
          surface: _bg,
        ),
        useMaterial3: true,
      ),
      home: const KairoAppView(),
    );
  }
}

class KairoAppView extends StatefulWidget {
  const KairoAppView({super.key});

  @override
  State<KairoAppView> createState() => _KairoAppViewState();
}

class _KairoAppViewState extends State<KairoAppView> {
  static final Uri _home = Uri.parse('https://kaironet.vercel.app/');
  late final WebViewController _web;
  int _progress = 0;
  bool _failed = false;
  bool _firstPaint = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (value) {
          if (!mounted) return;
          setState(() {
            _progress = value;
            _busy = value < 100;
          });
        },
        onPageStarted: (_) {
          if (!mounted) return;
          setState(() {
            _failed = false;
            _busy = true;
            _progress = 0;
          });
        },
        onPageFinished: (_) {
          if (!mounted) return;
          setState(() {
            _firstPaint = true;
            _busy = false;
            _progress = 100;
          });
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() {
              _failed = true;
              _busy = false;
            });
          }
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          // Keep the KAIRO site and its authentication/player redirects in the
          // same WebView so the existing site session and playback keep working.
          if (uri.scheme == 'https' || uri.scheme == 'http') {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(_home);
  }

  Future<bool> _onBack() async {
    if (await _web.canGoBack()) {
      await _web.goBack();
      return false;
    }
    return true;
  }

  Future<void> _retry() async {
    setState(() {
      _failed = false;
      _busy = true;
      _progress = 0;
    });
    await _web.loadRequest(_home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onBack();
        if (shouldExit && mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _web),
            if (_busy && !_firstPaint)
              const _LaunchScreen(),
            if (_busy && _firstPaint)
              Align(
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: _pink,
                  ),
                ),
              ),
            if (_failed)
              _NetworkError(onRetry: _retry),
          ],
        ),
      ),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.55),
          radius: 1.15,
          colors: [Color(0xFF281044), _bg, Color(0xFF05030A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_pink, _purple, Color(0xFFB7A0FF)],
              ).createShader(bounds),
              child: const Text(
                'KAIRO✦',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 112,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Color(0x443D2458),
                color: _pink,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Загружаем твой мир аниме…',
              style: TextStyle(color: Color(0xFFB8A9CA), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkError extends StatelessWidget {
  const _NetworkError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: _pink),
              const SizedBox(height: 18),
              const Text(
                'KAIRO пока не отвечает',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 9),
              const Text(
                'Проверь интернет и попробуй загрузить приложение ещё раз.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAAA0B8), height: 1.5),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
