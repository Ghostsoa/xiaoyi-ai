import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../components/loading_overlay.dart';
import '../../net/login/api_service.dart';
import '../../components/custom_snack_bar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviterIdController = TextEditingController();
  final _apiService = ApiService();
  final bool _isLoading = false;
  bool _isSendingCode = false;
  int _gender = 1;

  // 验证码倒计时相关
  Timer? _timer;
  int _countdown = 0;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          _timer = null;
        }
      });
    });
  }

  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text)) {
      CustomSnackBar.show(
        context,
        message: '请输入有效的邮箱地址',
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    final (success, message) = await LoadingOverlay.show(
      context,
      future: () => _apiService.sendCode(_emailController.text),
    );

    setState(() {
      _isSendingCode = false;
    });

    if (success && mounted) {
      CustomSnackBar.show(
        context,
        message: message,
      );
      _startCountdown();
    } else if (mounted) {
      CustomSnackBar.show(
        context,
        message: message,
      );
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final (success, message) = await LoadingOverlay.show(
        context,
        future: () => _apiService.register(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
          _codeController.text,
          gender: _gender,
          inviterId: _inviterIdController.text.isNotEmpty
              ? int.tryParse(_inviterIdController.text)
              : null,
        ),
      );

      if (success && mounted) {
        CustomSnackBar.show(
          context,
          message: message,
        );
        Navigator.pop(context, {
          'email': _emailController.text,
          'password': _passwordController.text,
        });
      } else if (mounted) {
        CustomSnackBar.show(
          context,
          message: message,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                30.0, 0, 30.0, MediaQuery.of(context).viewInsets.bottom + 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  // 欢迎标语
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '创建账号',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '开启你的AI助手之旅',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '让我们一起开始吧 ⭐',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // 注册表单
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '账号信息',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        CustomTextField(
                          controller: _emailController,
                          label: '邮箱',
                          hint: '请输入邮箱',
                          prefixIcon:
                              const Icon(Icons.email, color: Colors.white70),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '啊哦，邮箱地址还没填呢！🌟';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return '这个邮箱地址好像迷路了，帮它找到正确的路吧！🤨';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _codeController,
                                label: '验证码',
                                hint: '请输入验证码',
                                prefixIcon: const Icon(Icons.security,
                                    color: Colors.white70),
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '验证码呢？🔍';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120,
                              child: CustomButton(
                                text:
                                    _countdown > 0 ? '${_countdown}s' : '发送验证码',
                                isLoading: _isSendingCode,
                                onPressed: _countdown > 0 ? null : _sendCode,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _usernameController,
                          label: '用户名',
                          hint: '请输入用户名',
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.white70),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '给自己起个独特的名字吧！✨';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _passwordController,
                          label: '密码',
                          hint: '请输入密码',
                          obscureText: true,
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.white70),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '悄悄告诉你，没有密码可不行哦！🤫';
                            }
                            if (value.length < 6) {
                              return '这个密码有点单薄呢，再加点魔法进去吧！至少6位 ✨';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: '确认密码',
                          hint: '请再次输入密码',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.white70),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '再输入一次密码，让我确认是你本人哦！🔐';
                            }
                            if (value != _passwordController.text) {
                              return '两次密码不一样诶，是不是记错了呢？🤔';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '性别：',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Radio<int>(
                                value: 1,
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() => _gender = value!);
                                },
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return Colors.white.withOpacity(.32);
                                    }
                                    return Colors.white;
                                  },
                                ),
                              ),
                              const Text(
                                '男',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Radio<int>(
                                value: 2,
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() => _gender = value!);
                                },
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return Colors.white.withOpacity(.32);
                                    }
                                    return Colors.white;
                                  },
                                ),
                              ),
                              const Text(
                                '女',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _inviterIdController,
                          label: '邀请人ID',
                          hint: '请输入邀请人ID（选填）',
                          prefixIcon: const Icon(Icons.person_add,
                              color: Colors.white70),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final inviterId = int.tryParse(value);
                              if (inviterId == null) {
                                return '邀请人ID必须是数字哦 📝';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        CustomButton(
                          text: '立即创建账号 ➕',
                          isLoading: _isLoading,
                          onPressed: _register,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 20),
                        // 返回登录按钮
                        Center(
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('返回登录 (已有账号)'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '创建账号，开启AI助手之旅 ✨',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviterIdController.dispose();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}
