/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // 点击验证码状态
  String _captchaKey = '';
  Uint8List? _captchaImage;
  List<Map<String, dynamic>> _captchaTexts = [];
  final List<Map<String, int>> _clicks = [];
  String? _captchaError;

  /// 服务端生成的验证码图片为 300x200 原生像素
  static const double _nativeWidth = 300;
  static const double _nativeHeight = 200;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// POST /api/captcha/generate
  /// 返回: { key, image (base64 PNG), extra: { texts: [{order, text}] } }
  Future<void> _loadCaptcha() async {
    try {
      final api = Get.find<ApiService>();
      final response = await api.dio.post(ApiConfig.captchaGenerate, data: {'difficulty': 'medium'});
      final data = response.data['data'];
      final imageBase64 = data?['image']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _captchaKey = data?['key'] ?? '';
        _captchaImage = base64Decode(imageBase64.replaceFirst(RegExp(r'^data:image/\w+;base64,'), ''));
        _captchaTexts = List<Map<String, dynamic>>.from(data?['extra']?['texts'] ?? []);
        _clicks.clear();
        _captchaError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _captchaError = '验证码加载失败，请检查网络');
    }
  }

  /// 点击验证码图片，将组件坐标换算为图片原生坐标（300x200）后按顺序收集
  void _onCaptchaTap(TapUpDetails details, BoxConstraints constraints) {
    if (_captchaKey.isEmpty || _captchaImage == null) return;
    if (_clicks.length >= _captchaTexts.length) return;
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) return;

    final scaleX = _nativeWidth / constraints.maxWidth;
    final scaleY = _nativeHeight / constraints.maxHeight;
    final x = (details.localPosition.dx * scaleX).round().clamp(0, _nativeWidth.toInt());
    final y = (details.localPosition.dy * scaleY).round().clamp(0, _nativeHeight.toInt());

    setState(() => _clicks.add({'x': x, 'y': y}));
  }

  /// 按 order 排序后的点击顺序提示，如: "云" → "风" → "山"
  String get _captchaHint {
    final sorted = [..._captchaTexts]..sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
    final texts = sorted.map((t) => '"${t['text']}"').join(' → ');
    return texts.isEmpty ? '请点击刷新加载验证码' : '请按顺序点击图中文字: $texts';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_captchaKey.isEmpty || _captchaImage == null) {
      Get.snackbar('提示', '请先加载验证码', backgroundColor: Colors.orange.shade50);
      return;
    }
    if (_clicks.length < _captchaTexts.length) {
      Get.snackbar('提示', _captchaHint, backgroundColor: Colors.orange.shade50);
      return;
    }
    setState(() => _loading = true);
    try {
      await Get.find<AuthService>().login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        captchaKey: _captchaKey,
        clicks: _clicks,
      );
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('登录失败', e.toString(), backgroundColor: Colors.red.shade50);
      // 验证码一次有效（最多尝试 3 次），失败后重新生成
      _loadCaptcha();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: SizedBox(
            width: 440,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.apartment, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text('app_name'.tr, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('业主登录', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'phone_hint'.tr, prefixIcon: const Icon(Icons.phone_android)),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty) ? '请输入手机号' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'password_hint'.tr, prefixIcon: const Icon(Icons.lock_outline)),
                      obscureText: true,
                      validator: (v) => (v == null || v.isEmpty) ? '请输入密码' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildCaptcha(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('login_btn'.tr),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () {}, child: Text('no_account'.tr)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptcha() {
    if (_captchaImage == null) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text(_captchaError ?? '正在加载验证码...', style: TextStyle(fontSize: 13, color: _captchaError != null ? AppTheme.danger : Colors.grey)),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCaptcha, tooltip: '刷新验证码'),
        ],
      );
    }

    final expected = _captchaTexts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('captcha_hint'.tr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
            Text('已点击 ${_clicks.length}/$expected', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadCaptcha,
              tooltip: '刷新验证码',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_captchaHint, style: TextStyle(fontSize: 12, color: AppTheme.primary)),
        const SizedBox(height: 8),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (d) => _onCaptchaTap(d, constraints),
                child: SizedBox(
                  width: _nativeWidth,
                  height: _nativeHeight,
                  child: Stack(
                    children: [
                      Image.memory(_captchaImage!, width: _nativeWidth, height: _nativeHeight, fit: BoxFit.fill),
                      // 已点击位置标记（组件坐标 = 原生坐标，因为显示尺寸与原生尺寸一致）
                      for (var i = 0; i < _clicks.length; i++)
                        Positioned(
                          left: (_clicks[i]['x']!.toDouble() - 10),
                          top: (_clicks[i]['y']!.toDouble() - 10),
                          child: Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.85), shape: BoxShape.circle),
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_captchaError != null)
          Text(_captchaError!, style: TextStyle(fontSize: 12, color: AppTheme.danger)),
      ],
    );
  }
}
