import 'package:flutter/material.dart';
import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../components/loading_overlay.dart';
import '../../net/login/api_service.dart';
import '../../dao/storage_dao.dart';
import '../../components/custom_snack_bar.dart';
import '../../net/http_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _storageDao = StorageDao();
  final _httpClient = HttpClient();
  final bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // API节点相关
  late String _currentNode;
  final Map<String, int> _nodePingResults = {};
  bool _isPinging = false;
  bool _showNodeSelector = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
    _loadCurrentNode();
    _pingAllNodes();
  }

  // 加载当前节点设置
  void _loadCurrentNode() {
    _currentNode = _httpClient.getCurrentApiNode();
  }

  // Ping所有可用节点
  Future<void> _pingAllNodes() async {
    if (_isPinging) return;

    setState(() {
      _isPinging = true;
      _nodePingResults.clear();
    });

    final nodes = _httpClient.getAvailableNodes();
    for (final node in nodes) {
      final ping = await _httpClient.pingNode(node);
      if (mounted) {
        setState(() {
          _nodePingResults[node] = ping;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isPinging = false;
      });
    }
  }

  // 切换节点
  void _changeApiNode(String node) {
    if (node == _currentNode) return;

    _httpClient.updateApiNode(node);
    setState(() {
      _currentNode = node;
    });
    CustomSnackBar.show(
      context,
      message: '已切换到 $node 节点',
    );
  }

  // 构建延迟显示标签
  Widget _buildPingLabel(int ping) {
    if (ping < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '超时',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      );
    }

    Color bgColor;
    if (ping < 100) {
      bgColor = Colors.green.withOpacity(0.5);
    } else if (ping < 300) {
      bgColor = Colors.orange.withOpacity(0.5);
    } else {
      bgColor = Colors.red.withOpacity(0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$ping ms',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = _storageDao.getCredentials();

    // 如果有保存的邮箱，填充到输入框
    if (credentials['email'] != null) {
      setState(() {
        _emailController.text = credentials['email']!;
      });
    }

    // 只有当邮箱和密码都存在时，才设置密码并尝试自动登录
    if (credentials['email'] != null && credentials['password'] != null) {
      setState(() {
        _passwordController.text = credentials['password']!;
      });

      // 当有完整的凭证时，自动尝试登录
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _login(); // 直接调用登录按钮的方法
      });
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final (user, message) = await LoadingOverlay.show(
        context,
        future: () => _apiService.login(
          _emailController.text,
          _passwordController.text,
        ),
      );

      if (user != null && mounted) {
        // 保存登录凭证和用户信息
        await _storageDao.saveCredentials(
          _emailController.text,
          _passwordController.text,
        );
        await _storageDao.saveToken(user.token);
        await _storageDao.saveUser(user.toJson());

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (mounted) {
        CustomSnackBar.show(
          context,
          message: message ?? '登录失败',
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
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
                  const SizedBox(height: 100),
                  // 欢迎标语
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '小懿AI',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '你的专属AI角色扮演伙伴',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '让我们开始今天的角色扮演吧~ (◕ᴗ◕✿)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  // 登录表单
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              '欢迎回来',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            // 节点选择器开关 - 改进样式
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showNodeSelector = !_showNodeSelector;
                                  if (_showNodeSelector) {
                                    _pingAllNodes();
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.public,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _currentNode.split('.')[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      _showNodeSelector
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 节点选择器 - 改进样式
                        if (_showNodeSelector) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(top: 12, bottom: 20),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '选择服务器节点',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_isPinging)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '测速中...',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: _pingAllNodes,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.speed_outlined,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '刷新延迟',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 节点列表
                                for (final node
                                    in _httpClient.getAvailableNodes())
                                  GestureDetector(
                                    onTap: () {
                                      if (node != _currentNode) {
                                        _changeApiNode(node);
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: node == _currentNode
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: node == _currentNode
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            node == _currentNode
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  node,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _httpClient
                                                      .getNodeDescription(node),
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!_isPinging &&
                                              _nodePingResults
                                                  .containsKey(node))
                                            _buildPingLabel(
                                                _nodePingResults[node]!),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
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
                              return '咦？邮箱不见了，是不是被小精灵偷走了？🤔';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return '这个邮箱看起来怪怪的，再检查一下呗～🧐';
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
                              return '密码君害羞地躲起来了，快把它找出来！🙈';
                            }
                            if (value.length < 6) {
                              return '这个密码太短啦，至少6位哦 💪';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 5),
                        // 忘记密码链接
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/forgot-password',
                              ) as Map<String, String>?;

                              if (result != null && mounted) {
                                setState(() {
                                  _emailController.text = result['email'] ?? '';
                                  _passwordController.text =
                                      result['password'] ?? '';
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: const Text('忘记密码？'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: '进入角色扮演世界 ✨',
                          isLoading: _isLoading,
                          onPressed: _login,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 24),
                        // 注册链接
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '还没有专属角色？',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/register',
                                ) as Map<String, String>?;

                                if (result != null && mounted) {
                                  setState(() {
                                    _emailController.text =
                                        result['email'] ?? '';
                                    _passwordController.text =
                                        result['password'] ?? '';
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              child: const Text('立即创建账号 ➕'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            '你的AI角色正在等你哦~ (｡♥‿♥｡)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
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
}
