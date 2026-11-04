import 'anime_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _bg = Color(0xFF090611);
const _surface = Color(0xFF171021);
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
          surface: _surface,
        ),
        useMaterial3: true,
      ),
      home: const KairoAppView(),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class KairoAppView extends StatefulWidget {
  const KairoAppView({super.key});

  @override
  State<KairoAppView> createState() => _KairoAppViewState();
}

class _KairoAppViewState extends State<KairoAppView> {
  static const _base = 'https://kaironet.vercel.app/';
  static const _tabs = <_Tab>[
    _Tab('Главная', Icons.home_rounded, ''),
    _Tab('Каталог', Icons.grid_view_rounded, '#/vibe'),
    _Tab('Чат', Icons.forum_rounded, '#/chat'),
    _Tab('Избранное', Icons.favorite_rounded, '#/fav'),
    _Tab('Профиль', Icons.person_rounded, '#/me'),
  ];

  late final WebViewController _web;
  int _selected = 0;
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
        onPageFinished: (_) async {
          // The app owns the bottom navigation. Hide the website's duplicate
          // mobile dock while keeping the site's own routing and session.
          await _web.runJavaScript("""
            (function() {
              var style = document.getElementById('kairo-native-shell');
              if (!style) {
                style = document.createElement('style');
                style.id = 'kairo-native-shell';
                style.textContent = '.mobile-dock{display:none!important} body{padding-bottom:0!important}';
                document.head.appendChild(style);
              }
            })();
          """);
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
          if (uri.scheme == 'https' || uri.scheme == 'http') {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(_base));
  }

  Future<bool> _onBack() async {
    if (await _web.canGoBack()) {
      await _web.goBack();
      return false;
    }
    if (_selected != 0) {
      _openTab(0);
      return false;
    }
    return true;
  }

  Future<void> _openTab(int index) async {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _selected = index);
    await _web.loadRequest(Uri.parse('$_base${_tabs[index].route}'));
  }

  Future<void> _openSearch() async {
    await _openTab(1);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _web.runJavaScript("""
      (function() {
        var input = document.querySelector('#q');
        if (input) { input.focus(); input.scrollIntoView({block:'center'}); }
      })();
    """);
  }

  Future<void> _retry() async {
    setState(() {
      _failed = false;
      _busy = true;
      _progress = 0;
    });
    await _web.loadRequest(Uri.parse('$_base'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onBack();
        if (shouldExit && mounted) await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 18,
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_pink, _purple, Color(0xFFB7A0FF)],
            ).createShader(bounds),
            child: const Text(
              'KAIRO✦',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 23,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Поиск аниме',
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
            ),
            const SizedBox(width: 5),
          ],
          bottom: _busy && _firstPaint
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: _pink,
                  ),
                )
              : null,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _web),
            if (_busy && !_firstPaint) const _LaunchScreen(),
            if (_failed) _NetworkError(onRetry: _retry),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 68,
          backgroundColor: const Color(0xFF100B19),
          indicatorColor: _purple.withValues(alpha: .22),
          selectedIndex: _selected,
          onDestinationSelected: _openTab,
          destinations: _tabs.map((tab) => NavigationDestination(
            icon: Icon(tab.icon, size: 21),
            selectedIcon: Icon(tab.icon, size: 22, color: _pink),
            label: tab.label,
          )).toList(),
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
