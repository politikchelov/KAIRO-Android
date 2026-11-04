import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KairoLibrary {
  static const _historyKey = 'kairo_recent_anime_v1';
  static const _watchedKey = 'kairo_watched_episodes_v1';
  static const _notesKey = 'kairo_anime_notes_v1';
  static const _ratingsKey = 'kairo_anime_ratings_v1';

  static Future<List<Map<String, String>>> history() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_historyKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((e) =>
        Map<String, String>.from(e.map((k, v) => MapEntry(k.toString(), v.toString())))).toList();
    } catch (_) { return []; }
  }

  static Future<void> viewed({required String id, required String title, required String poster}) async {
    final p = await SharedPreferences.getInstance();
    final list = await history();
    list.removeWhere((e) => e['id'] == id);
    list.insert(0, {'id': id, 'title': title, 'poster': poster, 'opened': DateTime.now().toIso8601String()});
    await p.setString(_historyKey, jsonEncode(list.take(40).toList()));
  }

  static Future<void> clearHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_historyKey);
  }

  static Future<Set<String>> watched(String id) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_watchedKey);
    if (raw == null) return {};
    try {
      final all = Map<String, dynamic>.from(jsonDecode(raw));
      return Set<String>.from((all[id] as List? ?? []).map((e) => e.toString()));
    } catch (_) { return {}; }
  }

  static Future<void> toggleWatched(String id, String episode) async {
    final p = await SharedPreferences.getInstance();
    Map<String, dynamic> all = {};
    try { all = Map<String, dynamic>.from(jsonDecode(p.getString(_watchedKey) ?? '{}')); } catch (_) {}
    final set = Set<String>.from((all[id] as List? ?? []).map((e) => e.toString()));
    if (!set.add(episode)) set.remove(episode);
    all[id] = set.toList();
    await p.setString(_watchedKey, jsonEncode(all));
  }

  static Future<String> note(String id) async {
    final p = await SharedPreferences.getInstance();
    try { return Map<String, dynamic>.from(jsonDecode(p.getString(_notesKey) ?? '{}'))[id]?.toString() ?? ''; }
    catch (_) { return ''; }
  }

  static Future<void> saveNote(String id, String value) async {
    final p = await SharedPreferences.getInstance();
    Map<String, dynamic> all = {};
    try { all = Map<String, dynamic>.from(jsonDecode(p.getString(_notesKey) ?? '{}')); } catch (_) {}
    all[id] = value;
    await p.setString(_notesKey, jsonEncode(all));
  }

  static Future<int> rating(String id) async {
    final p = await SharedPreferences.getInstance();
    try { return (Map<String, dynamic>.from(jsonDecode(p.getString(_ratingsKey) ?? '{}'))[id] as num?)?.toInt() ?? 0; }
    catch (_) { return 0; }
  }

  static Future<void> setRating(String id, int value) async {
    final p = await SharedPreferences.getInstance();
    Map<String, dynamic> all = {};
    try { all = Map<String, dynamic>.from(jsonDecode(p.getString(_ratingsKey) ?? '{}')); } catch (_) {}
    all[id] = value;
    await p.setString(_ratingsKey, jsonEncode(all));
  }
}
