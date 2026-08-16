/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messages = <Map<String, String>>[];
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _send() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() { _messages.add({'role': 'user', 'content': q}); _loading = true; _controller.clear(); });
    try {
      final api = Get.find<ApiService>();
      final r = await api.dio.post(ApiConfig.chatAsk, data: {'question': q});
      setState(() => _messages.add({'role': 'assistant', 'content': r.data['data']?['answer'] ?? r.data['data']?.toString() ?? '抱歉，我无法回答这个问题。'}));
    } catch (e) { setState(() => _messages.add({'role': 'assistant', 'content': '网络错误，请重试。'})); }
    finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('智能问答')),
    body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: _messages.map((m) => Align(
        alignment: m['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: m['role'] == 'user' ? Colors.blue.shade100 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text(m['content'] ?? '', style: const TextStyle(fontSize: 14))))).toList())),
      if (_loading) const LinearProgressIndicator(),
      Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: '输入问题...', border: OutlineInputBorder()), onSubmitted: (_) => _send())),
        const SizedBox(width: 8), IconButton(icon: const Icon(Icons.send), onPressed: _send),
      ])),
    ]))),
  );
}
