import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kairo_backend.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import 'anime_catalog.dart';
import 'anime_detail.dart';
import 'favorites_screen.dart';

const _bg = Color(0xFF090611);
const _surface = Color(0xFF171021);
const _purple = Color(0xFF8B20F5);
const _pink = Color(0xFFE34BFF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kairoSupabaseUrl, anonKey: kairoSupabaseKey);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const KairoApp());
}

class KairoApp extends StatefulWidget {
  const KairoApp({super.key});
  @override
  State<KairoApp> createState() => _KairoAppState();
}

class _KairoAppState extends State<KairoApp> {
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = kairoSupabase.auth.currentSession;
    _authSubscription = kairoSupabase.auth.onAuthStateChange.listen((state) {
      if (mounted) setState(() => _session = state.session);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KAIRO',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bg,
      colorScheme: ColorScheme.fromSeed(seedColor: _purple, brightness: Brightness.dark, surface: _surface),
      useMaterial3: true,
    ),
    home: _session == null ? const AuthScreen() : const KairoShell(),
  );
}

class KairoShell extends StatefulWidget {
  const KairoShell({super.key});

  @override
  State<KairoShell> createState() => _KairoShellState();
}

class _KairoShellState extends State<KairoShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Главная'),
    NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Каталог'),
    NavigationDestination(icon: Icon(Icons.forum_rounded), label: 'Чат'),
    NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Избранное'),
    NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Профиль'),
  ];

  Future<void> _openSearch() async {
    setState(() => _index = 1);
    // The catalog owns its search field; no website scripting or WebView.
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeScreen(onOpenCatalog: () => setState(() => _index = 1)),
      AnimeCatalogScreen(onOpenAnime: _openAnime),
      const ChatScreen(),
      FavoritesScreen(onOpenAnime: _openAnime),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) setState(() => _index = 0);
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
            child: const Text('KAIRO✦', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900,
              letterSpacing: 1.5, fontSize: 23,
            )),
          ),
          actions: [
            IconButton(
              tooltip: 'Поиск аниме',
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          height: 68,
          backgroundColor: const Color(0xFF100B19),
          indicatorColor: _purple.withValues(alpha: .22),
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: _destinations,
        ),
      ),
    );
  }

  void _openAnime(String id) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AnimeDetailScreen(animeId: id),
    ));
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.onOpenCatalog});
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
    children: [
      const Text('ТВОЯ АНИМЕ-ВСЕЛЕННАЯ',
        style: TextStyle(color: _pink, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Добро пожаловать в KAIRO',
        style: TextStyle(fontSize: 27, height: 1.12, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF47206B), Color(0xFF1D1230), Color(0xFF110B1B)],
          ),
          border: Border.all(color: const Color(0x557C42B8)),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KAIRO ORIGINAL', style: TextStyle(color: Color(0xFFFFB6FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Истории, в которые хочется возвращаться.',
            style: TextStyle(fontSize: 23, height: 1.15, fontWeight: FontWeight.w900)),
          SizedBox(height: 10),
          Text('Исследуй каталог и открывай новые миры.',
            style: TextStyle(color: Color(0xFFD4C5E3), height: 1.4)),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('ТВОЙ СЛЕДУЮЩИЙ ШАГ',
        style: TextStyle(color: Color(0xFFB9A9CA), fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      _HomeAction(
        icon: Icons.grid_view_rounded,
        title: 'Открыть каталог',
        subtitle: 'Поиск и подбор аниме',
        onTap: onOpenCatalog,
      ),
      const SizedBox(height: 10),
      const _InfoTile(
        icon: Icons.construction_rounded,
        title: 'Приложение развивается',
        subtitle: 'Новые нативные разделы будут добавляться поэтапно.',
      ),
    ],
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          Icon(icon, color: _pink, size: 25),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: Color(0xFFB6A8C5), fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB6A8C5)),
        ]),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFF120D1B), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Icon(icon, color: _pink),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFFB6A8C5), fontSize: 12)),
      ])),
    ]),
  );
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title, required this.icon, required this.subtitle});
  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 54, color: _pink),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB6A8C5), height: 1.5)),
        const SizedBox(height: 18),
        const Text('Раздел ещё разрабатывается',
          style: TextStyle(color: Color(0xFFFFB6FF), fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

