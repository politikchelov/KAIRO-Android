import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'favorites_store.dart';

const _detailBg = Color(0xFF090611);
const _detailPanel = Color(0xFF171021);
const _detailPink = Color(0xFFE34BFF);

class AnimeDetailScreen extends StatefulWidget {
  const AnimeDetailScreen({super.key, required this.animeId});
  final String animeId;

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  Map<String, dynamic>? _anime;
  List<dynamic> _episodes = [];
  bool _loading = true;
  String? _error;
  int? _selectedEpisode;
  bool _isFavorite = false;
  bool _favoriteBusy = false;

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  dynamic _unwrap(dynamic value) {
    if (value is Map) return value['data'] ?? value['anime'] ?? value;
    return value;
  }

  List<dynamic> _episodeList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final candidates = [
        value['episodes'], _map(value['data'])['episodes'],
        value['data'], value['items'], value['results'],
        _map(value['data'])['items'], _map(value['data'])['results'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) return candidate;
      }
    }
    return [];
  }

  String _text(dynamic value) {
    if (value is String || value is num) return value.toString();
    if (value is Map) {
      for (final key in ['ru', 'russian', 'main', 'en', 'original', 'value', 'text']) {
        final candidate = value[key];
        if (candidate is String && candidate.trim().isNotEmpty) return candidate.trim();
      }
    }
    return '';
  }

  String _title(Map<String, dynamic> x) {
    final names = _map(x['names']);
    for (final value in [
      x['title_ru'], x['russian_title'], x['title'], x['name'],
      names['ru'], names['russian'], x['title_en'], names['en'],
      x['original_title'], x['shikimori'] is Map ? _map(x['shikimori'])['title'] : null,
    ]) {
      final valueText = _text(value);
      if (valueText.isNotEmpty) return valueText;
    }
    return 'Аниме';
  }

  String _poster(Map<String, dynamic> x) {
    final poster = _map(x['poster']);
    final image = _map(x['image']);
    final cover = _map(x['cover']);
    for (final value in [
      poster['original'], poster['large'], poster['full'], poster['url'], poster['src'],
      image['original'], image['large'], image['url'], image['src'],
      cover['original'], cover['large'], cover['url'],
      x['poster_url'], x['poster'], x['image'], x['cover'],
    ]) {
      final candidate = _text(value);
      if (candidate.startsWith('https://') || candidate.startsWith('http://')) return candidate;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final value = await FavoritesStore.contains(widget.animeId);
    if (mounted) setState(() => _isFavorite = value);
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    final anime = _anime ?? {};
    await FavoritesStore.toggle(FavoriteAnime(
      id: widget.animeId,
      title: _title(anime),
      poster: _poster(anime),
    ));
    if (!mounted) return;
    setState(() { _isFavorite = !_isFavorite; _favoriteBusy = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isFavorite ? 'Добавлено в избранное' : 'Убрано из избранного'),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final base = Uri.parse('https://kaironet.vercel.app/api/anivibe');
      final metaUri = base.replace(queryParameters: {'action': 'anime', 'id': widget.animeId});
      final epsUri = base.replace(queryParameters: {'action': 'episodes', 'id': widget.animeId});
      final responses = await Future.wait([
        http.get(metaUri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 20)),
        http.get(epsUri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 20)),
      ]);
      for (final response in responses) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          dynamic body;
          try { body = jsonDecode(response.body); } catch (_) { body = null; }
          throw Exception(body is Map ? (body['error'] ?? 'AniVibe: HTTP ${response.statusCode}') : 'AniVibe: HTTP ${response.statusCode}');
        }
      }
      final rawAnime = _unwrap(jsonDecode(responses[0].body));
      final anime = _map(rawAnime);
      final episodes = _episodeList(jsonDecode(responses[1].body));
      if (!mounted) return;
      setState(() {
        _anime = anime;
        _episodes = episodes;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  int _episodeNumber(dynamic episode, int index) {
    final row = _map(episode);
    for (final key in ['number', 'episode', 'ordinal', 'episode_number']) {
      final n = int.tryParse(_text(row[key]));
      if (n != null && n > 0) return n;
    }
    return index + 1;
  }

  @override
  Widget build(BuildContext context) {
    final anime = _anime ?? {};
    final title = _title(anime);
    final poster = _poster(anime);
    final description = _text(anime['description'] ?? anime['synopsis'] ?? anime['about'] ?? anime['description_ru']);
    final year = _text(anime['year']);
    final score = _text(anime['score'] ?? anime['rating']);
    return Scaffold(
      backgroundColor: _detailBg,
      appBar: AppBar(
        backgroundColor: _detailBg,
        title: const Text('KAIRO / ANIME'),
        actions: [IconButton(
          tooltip: _isFavorite ? 'Убрать из избранного' : 'В избранное',
          onPressed: _loading || _anime == null || _favoriteBusy ? null : _toggleFavorite,
          icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isFavorite ? _detailPink : Colors.white),
        )],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _detailPink))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: _detailPink,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 250,
                              width: double.infinity,
                              child: poster.isEmpty
                                  ? const ColoredBox(color: _detailPanel, child: Icon(Icons.movie_creation_outlined, size: 60, color: _detailPink))
                                  : Image.network(poster, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const ColoredBox(color: _detailPanel, child: Center(child: Icon(Icons.movie_creation_outlined, size: 60, color: _detailPink)))),
                            ),
                            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: .88)])))),
                            Positioned(left: 18, right: 18, bottom: 18,
                              child: Text(title, style: const TextStyle(fontSize: 25, height: 1.1, fontWeight: FontWeight.w900))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (year.isNotEmpty) _MetaChip(label: year),
                        if (score.isNotEmpty) _MetaChip(label: '★ $score'),
                        _MetaChip(label: '${_episodes.length} серий'),
                        const _MetaChip(label: 'AniVibe'),
                      ]),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('ОБ ЭТОЙ ИСТОРИИ', style: TextStyle(color: _detailPink, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(description, style: const TextStyle(color: Color(0xFFD0C5DA), height: 1.55)),
                      ],
                      const SizedBox(height: 24),
                      Row(children: [
                        const Expanded(child: Text('ЭПИЗОДЫ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                        Text('${_episodes.length} доступно', style: const TextStyle(color: Color(0xFFB6A8C5), fontSize: 12)),
                      ]),
                      const SizedBox(height: 12),
                      if (_episodes.isEmpty)
                        const Text('Список серий пока недоступен.', style: TextStyle(color: Color(0xFFB6A8C5)))
                      else
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: List.generate(_episodes.length, (index) {
                            final number = _episodeNumber(_episodes[index], index);
                            final selected = _selectedEpisode == index;
                            return InkWell(
                              onTap: () => setState(() => _selectedEpisode = index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 58,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected ? _detailPink.withValues(alpha: .22) : _detailPanel,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selected ? _detailPink : const Color(0xFF33253F)),
                                ),
                                child: Text(number.toString().padLeft(2, '0'),
                                  style: TextStyle(fontWeight: FontWeight.w900, color: selected ? Colors.white : const Color(0xFFD5C9E0))),
                              ),
                            );
                          }),
                        ),
                      if (_selectedEpisode != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _detailPanel, borderRadius: BorderRadius.circular(14)),
                          child: const Text('Выбор серии работает. Нативный видеоплеер подключим отдельным этапом — сейчас приложение не подменяет его веб-страницей.',
                            style: TextStyle(color: Color(0xFFD0C5DA), height: 1.45, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: _detailPanel, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF33253F))),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFE3D6EF), fontWeight: FontWeight.w700)),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, color: _detailPink, size: 46),
        const SizedBox(height: 14),
        const Text('Не удалось загрузить аниме', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB6A8C5))),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Повторить')),
      ]),
    ),
  );
}
