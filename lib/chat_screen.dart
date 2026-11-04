import 'package:flutter/material.dart';
import 'kairo_backend.dart';

const _chatPink = Color(0xFFE34BFF);
const _chatPanel = Color(0xFF171021);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  late final Stream<List<Map<String, dynamic>>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = kairoSupabase.from('messages').stream(primaryKey: ['id']).order('created_at');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = kairoSupabase.auth.currentUser;
    if (text.isEmpty || user == null || _sending) return;
    setState(() => _sending = true);
    try {
      final profile = await kairoMyProfile();
      if (profile['banned'] == true || profile['muted'] == true) {
        throw Exception(profile['banned'] == true ? 'Аккаунт заблокирован' : 'Отправка сообщений ограничена');
      }
      await kairoSupabase.from('messages').insert({
        'uid': user.id,
        'name': (profile['name'] ?? 'KAIRO user').toString(),
        'color': (profile['accent'] ?? '#E34BFF').toString(),
        'role': (profile['role'] ?? 'user').toString(),
        'avatar': (profile['avatar'] ?? '').toString(),
        'badge': (profile['badge'] ?? '').toString(),
        'text': text,
      });
      _controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ОБЩИЙ ЧАТ', style: TextStyle(color: _chatPink, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('KAIRO Community', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        ])),
        IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded)),
      ]),
    ),
    Expanded(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messages,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Не удалось загрузить чат: ${snapshot.error}', textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB6A8C5))),
          ));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _chatPink));
          final rows = snapshot.data!;
          if (rows.isEmpty) return const Center(child: Text('Пока тихо. Начни общение первым.'));
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[rows.length - 1 - index];
              final mine = row['uid'] == kairoSupabase.auth.currentUser?.id;
              final role = (row['role'] ?? 'user').toString();
              final name = (row['name'] ?? 'Пользователь').toString();
              final body = (row['text'] ?? '').toString();
              final stamp = DateTime.tryParse((row['created_at'] ?? '').toString())?.toLocal();
              final time = stamp == null ? '' : '${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}';
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .82),
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 9),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFF38204B) : _chatPanel,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: mine ? const Color(0x668B20F5) : const Color(0x221FFFFFFF)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _chatPink, fontSize: 12, fontWeight: FontWeight.w800))),
                      if (role != 'user') ...[
                        const SizedBox(width: 6),
                        Text(role.toUpperCase(), style: const TextStyle(fontSize: 8, color: Color(0xFFFFC2FF), fontWeight: FontWeight.w900)),
                      ],
                    ]),
                    const SizedBox(height: 5),
                    Text(body, style: const TextStyle(height: 1.35)),
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerRight,
                      child: Text(time, style: const TextStyle(fontSize: 9, color: Color(0xFFAA9BB8)))),
                  ]),
                ),
              );
            },
          );
        },
      ),
    ),
    SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: const BoxDecoration(color: Color(0xFF100B19), border: Border(top: BorderSide(color: Color(0x332F2040)))),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _controller, minLines: 1, maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Написать сообщение…', filled: true, fillColor: _chatPanel,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _send(),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF8126C7)),
            icon: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_rounded),
          ),
        ]),
      ),
    ),
  ]);
}
