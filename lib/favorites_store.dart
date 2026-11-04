import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteAnime {
  const FavoriteAnime({required this.id, required this.title, this.poster = ''});
  final String id;
  final String title;
  final String poster;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'poster': poster};
  factory FavoriteAnime.fromJson(Map<String, dynamic> json) => FavoriteAnime(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Аниме',
    poster: json['poster']?.toString() ?? '',
  );
}

class FavoritesStore {
  static const _key = 'kairo_local_favorites_v1';

  static Future<List<FavoriteAnime>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.whereType<Map>().map((x) =>
        FavoriteAnime.fromJson(Map<String, dynamic>.from(x))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> contains(String id) async =>
      (await all()).any((item) => item.id == id);

  static Future<void> toggle(FavoriteAnime anime) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await all();
    if (items.any((item) => item.id == anime.id)) {
      items.removeWhere((item) => item.id == anime.id);
    } else {
      items.insert(0, anime);
    }
    await prefs.setString(_key, jsonEncode(items.map((x) => x.toJson()).toList()));
  }

  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await all();
    items.removeWhere((item) => item.id == id);
    await prefs.setString(_key, jsonEncode(items.map((x) => x.toJson()).toList()));
  }
}
