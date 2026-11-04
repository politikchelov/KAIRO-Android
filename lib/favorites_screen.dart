import 'package:flutter/material.dart';
import 'favorites_store.dart';

const _favPink = Color(0xFFE34BFF);
const _favPanel = Color(0xFF171021);

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenAnime});
  final ValueChanged<String> onOpenAnime;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteAnime> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await FavoritesStore.all();
    if (!mounted) return;
    setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: _favPink,
    onRefresh: _load,
    child: _loading
      ? ListView(children: const [SizedBox(height: 220), Center(child: CircularProgressIndicator(color: _favPink))])
      : _items.isEmpty
        ? ListView(children: const [
            SizedBox(height: 120),
            Icon(Icons.favorite_border_rounded, size: 58, color: _favPink),
            SizedBox(height: 14),
            Center(child: Text('Пока ничего нет', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            SizedBox(height: 7),
            Center(child: Text('Добавляй аниме в избранное на странице тайтла.', style: TextStyle(color: Color(0xFFB6A8C5)), textAlign: TextAlign.center)),
          ])
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Material(
                color: _favPanel,
                borderRadius: BorderRadius.circular(15),
                child: ListTile(
                  onTap: () => widget.onOpenAnime(item.id),
                  contentPadding: const EdgeInsets.all(9),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(width: 54, height: 72,
                      child: item.poster.isEmpty
                        ? const ColoredBox(color: Color(0xFF281A35), child: Icon(Icons.movie, color: _favPink))
                        : Image.network(item.poster, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF281A35), child: Icon(Icons.movie, color: _favPink))),
                    ),
                  ),
                  title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Открыть страницу аниме', style: TextStyle(color: Color(0xFFB6A8C5))),
                  trailing: IconButton(
                    tooltip: 'Убрать из избранного',
                    icon: const Icon(Icons.favorite, color: _favPink),
                    onPressed: () async { await FavoritesStore.remove(item.id); _load(); },
                  ),
                ),
              );
            },
          ),
  );
}
