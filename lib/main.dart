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
import 'history_screen.dart';

const _bg = Color(0xFFFFF3F0);
const _surface = Color(0xFFFFFFFF);
const _purple = Color(0xFFEF7166);
const _pink = Color(0xFFEF7166);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kairoSupabaseUrl, anonKey: kairoSupabaseKey);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: _bg,
    systemNavigationBarIconBrightness: Brightness.dark,
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
      brightness: Brightness.light,
      scaffoldBackgroundColor: _bg,
      colorScheme: ColorScheme.fromSeed(seedColor: _purple, brightness: Brightness.light, surface: _surface),
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
      _HomeScreen(onOpenCatalog: () => setState(() => _index = 1), onOpenHistory: _openHistory),
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
              colors: [_pink, _purple, Color(0xFFFFA79E)],
            ).createShader(bounds),
            child: const Text('KAIRO✦', style: TextStyle(
              color: const Color(0xFF30201D), fontWeight: FontWeight.w900,
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
          backgroundColor: const Color(0xFFFFE7E2),
          indicatorColor: const Color(0xFFFFD5CE),
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: _destinations,
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(onOpenAnime: _openAnime),
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
  const _HomeScreen({
    required this.onOpenCatalog,
    required this.onOpenHistory,
  });
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
    children: [
      Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KAIRO ANIME CLUB', style: TextStyle(color: Color(0xFFB94842), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('Привет, анимешник!', style: TextStyle(color: Color(0xFF30201D), fontSize: 23, fontWeight: FontWeight.w900)),
        ])),
        CircleAvatar(radius: 23, backgroundColor: Color(0xFFFFD8D1),
          child: Icon(Icons.person_rounded, color: Color(0xFFB94842))),
      ]),
      const SizedBox(height: 18),
      Container(
        height: 310,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFF766B), Color(0xFFFFA99F), Color(0xFFFFD4CC)]),
          boxShadow: const [BoxShadow(color: Color(0x33B94842), blurRadius: 24, offset: Offset(0, 14))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned(right: -45, top: -55, child: Container(width: 230, height: 230,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0x55FFFFFF), width: 3)))),
          Positioned(right: 18, bottom: -85, child: Container(width: 250, height: 250,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Color(0x66FFFFFF), width: 3)))),
          Positioned(left: 18, top: 18, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: const Text('100+ АНИМЕ ✦', style: TextStyle(color: Color(0xFF30201D), fontWeight: FontWeight.w900, fontSize: 11)))),
          Positioned(left: 20, right: 18, bottom: 22, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ТВОЯ СЛЕДУЮЩАЯ\nАНИМЕ-ИСТОРИЯ', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.02, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text('Открывай новые миры и находи любимые тайтлы', style: TextStyle(color: Color(0xFFFFF8F6), fontSize: 12, height: 1.4)),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onOpenCatalog,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Смотреть аниме'),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFB94842),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
            ),
          ])),
        ]),
      ),
      const SizedBox(height: 25),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('ОТКРЫВАЙ НОВОЕ', style: TextStyle(color: Color(0xFF30201D), fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: .5)),
        TextButton(onPressed: onOpenCatalog, child: const Text('Весь каталог')),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _HomeFeature(icon: Icons.local_fire_department_rounded, title: 'Популярное', subtitle: 'Что сейчас смотрят', onTap: onOpenCatalog)),
        const SizedBox(width: 10),
        Expanded(child: _HomeFeature(icon: Icons.auto_awesome_rounded, title: 'Новинки', subtitle: 'Свежие тайтлы', onTap: onOpenCatalog)),
      ]),
      const SizedBox(height: 12),
      _HomeAction(icon: Icons.grid_view_rounded, title: 'Открыть каталог', subtitle: 'Поиск, жанры и подбор аниме', onTap: onOpenCatalog),
      const SizedBox(height: 10),
      _HomeAction(icon: Icons.history_rounded, title: 'История просмотров', subtitle: 'Продолжи знакомство с недавно открытыми тайтлами', onTap: onOpenHistory),
    ],
  );
}

class _HomeFeature extends StatelessWidget {
  const _HomeFeature({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFE3DE), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFFB94842))),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Color(0xFF30201D), fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Color(0xFF927A75), fontSize: 11)),
      ])),
    ),
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
            Text(subtitle, style: const TextStyle(color: Color(0xFF927A75), fontSize: 12)),
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
    decoration: BoxDecoration(color: const Color(0xFFFFE7E2), borderRadius: BorderRadius.circular(16)),
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

