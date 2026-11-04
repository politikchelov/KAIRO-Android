import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kairo_backend.dart';

const _profilePink = Color(0xFFEF7166);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final value = await kairoMyProfile();
      if (mounted) setState(() { _profile = value; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _profilePink));
    if (_error != null || _profile == null) return Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.person_off_rounded, size: 46, color: _profilePink),
        const SizedBox(height: 10),
        Text(_error ?? 'Профиль не найден', textAlign: TextAlign.center),
        TextButton(onPressed: _load, child: const Text('Повторить')),
      ],
    ));
    final p = _profile!;
    final name = (p['name'] ?? 'KAIRO user').toString();
    final role = (p['role'] ?? 'user').toString();
    final bio = (p['bio'] ?? '').toString();
    final avatar = (p['avatar'] ?? '').toString();
    final banner = (p['banner'] ?? '').toString();
    return RefreshIndicator(
      color: _profilePink, onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 30), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: SizedBox(height: 150, child: Stack(fit: StackFit.expand, children: [
            if (banner.startsWith('http')) Image.network(banner, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF2D8D3)))
            else const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              colors: [Color(0xFFFF9C91), Color(0xFFE96D62)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              colors: [Colors.transparent, Color(0xAA090611)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            Positioned(left: 16, bottom: 14, child: Text(name,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
          ])),
        ),
        Transform.translate(
          offset: const Offset(18, -27),
          child: Row(children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFE7E2),
                border: Border.all(color: _profilePink, width: 3)),
              clipBehavior: Clip.antiAlias,
              child: avatar.startsWith('http')
                ? Image.network(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40))
                : const Icon(Icons.person, size: 40, color: _profilePink),
            ),
            const SizedBox(width: 12),
            Padding(padding: const EdgeInsets.only(top: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role.toUpperCase(), style: const TextStyle(color: _profilePink, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              if ((p['badge'] ?? '').toString().isNotEmpty)
                Text(p['badge'].toString(), style: const TextStyle(color: Color(0xFFB94842), fontSize: 11)),
            ])),
          ]),
        ),
        if (bio.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 18),
          child: Text(bio, style: const TextStyle(color: Color(0xFF765E59), height: 1.45))),
        _info('Статус', (p['status'] ?? '').toString().isEmpty ? 'Не указан' : p['status'].toString()),
        _info('Аккаунт', kairoSupabase.auth.currentUser?.email ?? 'KAIRO'),
        _info('Роль', role),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () async {
            await kairoSupabase.auth.signOut();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Выйти из аккаунта'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB94842),
            side: const BorderSide(color: Color(0x66FF718F)), padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ]),
    );
  }

  Future<void> _editProfile() async {\n    final bioController=TextEditingController(text:(_profile?['bio']??'').toString());\n    final statusController=TextEditingController(text:(_profile?['status']??'').toString());\n    final result=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(\n      title:const Text('Мой профиль'),content:Column(mainAxisSize:MainAxisSize.min,children:[\n        TextField(controller:statusController,maxLength:60,decoration:const InputDecoration(labelText:'Статус')),\n        const SizedBox(height:8),TextField(controller:bioController,maxLength:240,maxLines:4,decoration:const InputDecoration(labelText:'О себе')),\n      ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Сохранить'))]));\n    if(result!=true)return;\n    try {\n      final id=kairoSupabase.auth.currentUser?.id;\n      if(id==null)return;\n      await kairoSupabase.from('profiles').update({'status':statusController.text.trim(),'bio':bioController.text.trim()}).eq('id',id);\n      await _load();\n      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Профиль обновлён')));\n    } catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Не удалось сохранить: $e'))); }\n  }\n\n  Widget _info(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(13)),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Color(0xFF927A75), fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
    ]),
  );
}
