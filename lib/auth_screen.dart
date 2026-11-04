import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kairo_backend.dart';

const _authPink = Color(0xFFE34BFF);
const _authPanel = Color(0xFF171021);

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
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Введи ник и пароль');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await kairoSupabase.auth.signInWithPassword(
        email: kairoInternalEmail(username),
        password: password,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось подключиться. Проверь интернет.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF090611),
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
                const Text('Войди в свой аккаунт', textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB6A8C5))),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _authPanel, borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x447C42B8))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('НИК', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: _authPink, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _username, textInputAction: TextInputAction.next,
                      autocorrect: false, decoration: _decoration('Твой ник')),
                    const SizedBox(height: 18),
                    const Text('ПАРОЛЬ', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: _authPink, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _password, obscureText: _obscure,
                      textInputAction: TextInputAction.done, onSubmitted: (_) => _signIn(),
                      decoration: _decoration('Пароль').copyWith(
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
                      onPressed: _busy ? null : _signIn,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8126C7),
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ВОЙТИ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                const Text('Используй существующий ник и пароль KAIRO. Регистрация пока выполняется через сайт — мобильный API регистрации требует отдельной безопасной настройки.',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94869F), fontSize: 11, height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: const Color(0xFF0D0914),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
