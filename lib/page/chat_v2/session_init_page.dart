import 'package:flutter/material.dart';
import '../../net/session/session_service.dart';
import 'agent_chat_page.dart';
import 'dart:convert';
import 'dart:async';

class SessionInitPage extends StatefulWidget {
  final String sessionId;
  final String sessionName;
  final List<String> initFields;
  final String? coverBase64;
  final String? backgroundBase64;

  const SessionInitPage({
    super.key,
    required this.sessionId,
    required this.sessionName,
    required this.initFields,
    this.coverBase64,
    this.backgroundBase64,
  });

  @override
  State<SessionInitPage> createState() => _SessionInitPageState();
}

class _SessionInitPageState extends State<SessionInitPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final _sessionService = SessionService();
  bool _isSubmitting = false;

  // 步骤控制
  int _currentStep = 0;
  int _totalSteps = 0;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  // 欢迎界面状态
  bool _showWelcome = true;
  bool _readyToStart = false;

  // 缓存图片
  ImageProvider? _backgroundImage;
  ImageProvider? _coverImage;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();

    // 为每个初始化字段创建一个控制器
    for (final field in widget.initFields) {
      _controllers[field] = TextEditingController();
    }

    // 设置总步骤数
    _totalSteps = widget.initFields.length;

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));

    // 预加载图片
    _preloadImages();

    // 自动开始动画
    _animationController.forward();

    // 欢迎动画结束后自动进入准备状态，减少延迟时间
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _readyToStart = true;
        });
      }
    });
  }

  // 预加载图片
  Future<void> _preloadImages() async {
    if (widget.backgroundBase64 != null &&
        widget.backgroundBase64!.isNotEmpty) {
      try {
        final imageData = base64Decode(widget.backgroundBase64!
            .replaceFirst(RegExp(r'data:image/[^;]+;base64,'), ''));
        _backgroundImage = MemoryImage(imageData);

        // 预缓存背景图片
        await precacheImage(_backgroundImage!, context);
      } catch (e) {
        print('背景图片加载错误: $e');
      }
    }

    if (widget.coverBase64 != null && widget.coverBase64!.isNotEmpty) {
      try {
        final imageData = base64Decode(widget.coverBase64!
            .replaceFirst(RegExp(r'data:image/[^;]+;base64,'), ''));
        _coverImage = MemoryImage(imageData);

        // 预缓存封面图片
        await precacheImage(_coverImage!, context);
      } catch (e) {
        print('封面图片加载错误: $e');
      }
    }

    if (mounted) {
      setState(() {
        _imagesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    // 释放所有控制器
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  // 移动到下一步
  void _nextStep() {
    // 如果是选择类型字段，确保用户已选择
    final currentField = widget.initFields[_currentStep];
    if (currentField.contains('/') &&
        (_controllers[currentField]?.text.isEmpty ?? true)) {
      setState(() {
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择一个选项')),
        );
      });
      return;
    }

    // 验证当前步骤
    if (_formKey.currentState!.validate()) {
      _animationController.reset();
      setState(() {
        if (_currentStep < _totalSteps - 1) {
          _currentStep++;
        } else {
          _submitForm();
        }
      });
      _animationController.forward();
    }
  }

  // 移动到上一步
  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() {
        _currentStep--;
      });
      _animationController.forward();
    }
  }

  // 开始引导流程
  void _startGuide() {
    _animationController.reset();
    setState(() {
      _showWelcome = false;
    });
    _animationController.forward();
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 收集所有字段的值
      final Map<String, String> initFields = {};
      for (final entry in _controllers.entries) {
        initFields[entry.key] = entry.value.text.trim();
      }

      // 提交初始化请求
      final response = await _sessionService.initializeSession(
        widget.sessionId,
        initFields,
      );

      if (mounted && response['code'] == 200) {
        // 初始化成功，跳转到聊天页面
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AgentChatPage(
                sessionId: widget.sessionId,
                sessionName: widget.sessionName,
                backgroundBase64: widget.backgroundBase64,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // 设置resizeToAvoidBottomInset为false，防止键盘弹出时页面被压缩
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: _showWelcome
            ? null
            : Text(
                '步骤 ${_currentStep + 1}/$_totalSteps',
                style: const TextStyle(color: Colors.white),
              ),
      ),
      body: Stack(
        children: [
          // 背景图片 - 使用缓存的图片
          Positioned.fill(
            child: _buildBackground(),
          ),

          // 半透明遮罩
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // 主要内容
          SafeArea(
            child: _showWelcome ? _buildWelcomeScreen() : _buildStepContent(),
          ),
        ],
      ),
    );
  }

  // 构建背景
  Widget _buildBackground() {
    // 如果背景图片已加载，使用缓存的图片
    if (_backgroundImage != null && _imagesLoaded) {
      return Image(
        image: _backgroundImage!,
        fit: BoxFit.cover,
        gaplessPlayback: true, // 防止重新加载时闪烁
      );
    } else {
      // 默认渐变背景
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade800,
              Colors.purple.shade800,
            ],
          ),
        ),
      );
    }
  }

  // 欢迎界面
  Widget _buildWelcomeScreen() {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 头像或图标
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _buildCoverImage(),
                ),
                const SizedBox(height: 40),

                // 欢迎文本
                Text(
                  widget.sessionName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '准备开始一段新的对话',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 80),

                // 开始按钮
                AnimatedOpacity(
                  opacity: _readyToStart ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: _readyToStart ? 200 : 160,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _readyToStart ? _startGuide : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '准备好了',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建封面图片 - 使用缓存的图片
  Widget _buildCoverImage() {
    if (_coverImage != null && _imagesLoaded) {
      return ClipOval(
        child: Image(
          image: _coverImage!,
          fit: BoxFit.cover,
          gaplessPlayback: true, // 防止重新加载时闪烁
        ),
      );
    } else {
      return Icon(
        Icons.person,
        size: 60,
        color: Colors.white.withOpacity(0.8),
      );
    }
  }

  // 构建当前步骤内容
  Widget _buildStepContent() {
    final currentField = widget.initFields[_currentStep];
    final isLastStep = _currentStep == _totalSteps - 1;

    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 进度指示器
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 40),

              // 字段标题和描述
              Text(
                _getFieldDisplayName(currentField),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getFieldDescription(currentField),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 表单字段
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildField(currentField),
                  ),
                ),
              ),

              // 导航按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 上一步按钮
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('上一步'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 100),

                  // 下一步/完成按钮
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : Row(
                            children: [
                              Text(
                                isLastStep ? '完成' : '下一步',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastStep ? Icons.check : Icons.arrow_forward,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取字段显示名称
  String _getFieldDisplayName(String field) {
    // 如果是选择字段，固定显示"选择一个适合你的"
    if (field.contains('/')) {
      return '选择一个适合你的';
    }
    return field;
  }

  // 获取字段描述
  String _getFieldDescription(String field) {
    // 为不同类型字段提供友好的描述
    if (field.contains('/')) {
      return '请从下列选项中选择一个合适的选项';
    } else if (field.contains('名字') || field.contains('姓名')) {
      return '请输入您想使用的名字';
    } else if (field.contains('年龄')) {
      return '请输入您的年龄';
    } else if (field.contains('职业')) {
      return '请告诉我您的职业是什么';
    } else {
      return '请填写以下信息';
    }
  }

  Widget _buildField(String field) {
    // 检查是否是选择字段（包含/的字段）
    if (field.contains('/')) {
      final options = field.split('/');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '请选择一个选项:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ...options
                    .map((option) => _buildOptionItem(field, option))
                    .toList(),
              ],
            ),
          ),
        ],
      );
    }

    // 普通文本输入字段
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: TextFormField(
            controller: _controllers[field],
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              hintText: '请输入$field',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入$field';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  // 构建选项项
  Widget _buildOptionItem(String field, String option) {
    final isSelected = _controllers[field]!.text == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _controllers[field]!.text = option;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
