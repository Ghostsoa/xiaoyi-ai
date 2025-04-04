import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../components/loading_overlay.dart';
import '../../net/login/api_service.dart';
import '../../components/custom_snack_bar.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isSendingCode = false;
  bool _isResetting = false;

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
      future: () => _apiService.sendForgotPasswordCode(_emailController.text),
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

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isResetting = true;
      });

      final (success, message) = await LoadingOverlay.show(
        context,
        future: () => _apiService.resetPassword(
          _emailController.text,
          _codeController.text,
          _passwordController.text,
        ),
      );

      setState(() {
        _isResetting = false;
      });

      if (success && mounted) {
        CustomSnackBar.show(
          context,
          message: message,
        );
        // 返回登录页面，并带上邮箱和密码
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
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '重置密码',
          style: TextStyle(color: Colors.white),
        ),
      ),
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
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(30.0, 20.0, 30.0,
                MediaQuery.of(context).viewInsets.bottom + 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '找回密码',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '请输入您的注册邮箱，我们将向您发送验证码',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomTextField(
                      controller: _emailController,
                      label: '邮箱',
                      hint: '请输入注册邮箱',
                      prefixIcon:
                          const Icon(Icons.email, color: Colors.white70),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱地址';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                return '请输入验证码';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          child: TextButton(
                            onPressed: _countdown > 0 || _isSendingCode
                                ? null
                                : _sendCode,
                            style: TextButton.styleFrom(
                              backgroundColor: _countdown > 0 || _isSendingCode
                                  ? Colors.grey.withOpacity(0.5)
                                  : Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _countdown > 0
                                  ? '重新发送($_countdown)'
                                  : _isSendingCode
                                      ? '发送中...'
                                      : '获取验证码',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: '新密码',
                      hint: '请输入新密码',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入新密码';
                        }
                        if (value.length < 6) {
                          return '密码长度至少为6位';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: '确认新密码',
                      hint: '请再次输入新密码',
                      obscureText: true,
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.white70),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请确认新密码';
                        }
                        if (value != _passwordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    CustomButton(
                      text: '重置密码',
                      isLoading: _isResetting,
                      onPressed: _resetPassword,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '重置密码后，将使用新密码登录',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
