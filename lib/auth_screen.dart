import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kairo_backend.dart';

const _authPink = Color(0xFFEF7166);
const _authPanel = Color(0xFFFFFFFF);
const _redirectUrl = 'com.kairo.app.kairo_android://login-callback/';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _register = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Введи ник и пароль');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Пароль должен содержать минимум 8 символов');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final response = await kairoSupabase.functions.invoke(
        'kairo-mobile-auth',
        body: {
          'action': _register ? 'register' : 'login',
          'username': username,
          'password': password,
        },
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300 || data is! Map) {
        throw Exception(data is Map && data['error'] is String
            ? data['error'] as String
            : 'Не удалось выполнить запрос. Попробуй ещё раз.');
      }
      final refreshToken = data['refresh_token'];
      if (refreshToken is! String || refreshToken.isEmpty) {
        throw Exception('Сервер не вернул токен входа. Попробуй войти ещё раз.');
      }
      await kairoSupabase.auth.setSession(refreshToken);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] is String
          ? details['error'] as String
          : e.reasonPhrase ?? 'Ошибка сервера авторизации';
      if (mounted) setState(() => _error = message);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() { _busy = true; _error = null; });
    try {
      await kairoSupabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: const Color(0xFFFFF8F6),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF3F0),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.auto_awesome, color: _authPink, size: 42),
                const SizedBox(height: 12),
                const Text('KAIRO✦', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 8),
                Text(_register ? 'Создай свой аккаунт KAIRO' : 'Войди в свой аккаунт',
                  textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF927A75))),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _authPanel, borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x447C42B8))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Вход')),
                        ButtonSegment(value: true, label: Text('Регистрация')),
                      ],
                      selected: {_register},
                      onSelectionChanged: _busy ? null : (value) {
                        setState(() { _register = value.first; _error = null; });
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 22),
                    const Text('НИК', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: _authPink, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _username, textInputAction: TextInputAction.next,
                      autocorrect: false, enableSuggestions: false, decoration: _decoration('Твой ник')),
                    const SizedBox(height: 18),
                    const Text('ПАРОЛЬ', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: _authPink, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _password, obscureText: _obscure,
                      textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(),
                      decoration: _decoration('Минимум 8 символов').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      )),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Color(0xFFFF8A9A), fontSize: 12)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF7166),
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_register ? 'СОЗДАТЬ АККАУНТ' : 'ВОЙТИ',
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Expanded(child: Divider(color: Color(0xFFF0D8D3))),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ИЛИ', style: TextStyle(color: Color(0xFF927A75), fontSize: 10))),
                      Expanded(child: Divider(color: Color(0xFFF0D8D3))),
                    ]),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _google,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Text('Продолжить с Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF30201D),
                        side: const BorderSide(color: Color(0xFFE8C8C2)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Вход и регистрация используют общую базу аккаунтов KAIRO. Google откроется в защищённом окне браузера.',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF927A75), fontSize: 11, height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
