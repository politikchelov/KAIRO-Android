import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

const kairoSupabaseUrl = 'https://pmyfmmkitmofndybvvaq.supabase.co';
const kairoSupabaseKey = 'sb_publishable_EJ10uEKBu93h_fiu9Fn9QQ_kSIBXzsl';

final kairoSupabase = Supabase.instance.client;

String kairoInternalEmail(String username) {
  final normalized = username.trim().toLowerCase();
  final digest = sha256.convert(utf8.encode(normalized)).toString();
  return 'u_${digest}@accounts.kairo.invalid';
}

Future<Map<String, dynamic>> kairoMyProfile() async {
  final user = kairoSupabase.auth.currentUser;
  if (user == null) throw Exception('Сначала войди в аккаунт');
  final row = await kairoSupabase.from('profiles').select().eq('id', user.id).maybeSingle();
  if (row == null) throw Exception('Профиль не найден');
  return Map<String, dynamic>.from(row);
}
