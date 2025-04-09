import 'package:flutter/material.dart';
import '../../dao/storage_dao.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../main.dart';
import '../../components/custom_snack_bar.dart';
import '../../components/custom_dialog.dart';
import '../../net/profile/profile_service.dart';
import '../../service/chat_history_service.dart';
import '../../dao/chat_history_dao.dart';
import '../../dao/character_card_dao.dart';
import '../../service/character_card_service.dart';
import '../../utils/chat_export_import_util.dart';
import '../../components/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/import_page.dart';
import '../about/about_page.dart';
import '../../net/http_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storageDao = StorageDao();
  final _profileService = ProfileService();
  final _httpClient = HttpClient();
  String _currentNode = '';

  Color _primaryColor = const Color(0xFF6C72CB); // 使用默认值初始化
  Color _secondaryColor = const Color(0xFF88A0BF); // 使用默认值初始化
  Color _originalPrimaryColor = const Color(0xFF6C72CB);
  Color _originalSecondaryColor = const Color(0xFF88A0BF);
  bool _hasChanges = false;
  bool _followPrimaryColor = false; // 添加次色调跟随开关状态

  // 默认颜色
  static const Color defaultPrimaryColor = Color(0xFF6C72CB);
  static const Color defaultSecondaryColor = Color(0xFF88A0BF);

  @override
  void initState() {
    super.initState();
    _loadThemeColors();
    _loadFollowPrimaryColorSetting();
    _loadCurrentNode();
  }

  Future<void> _loadThemeColors() async {
    final colors = await _storageDao.getThemeColors();
    setState(() {
      _primaryColor = colors.$1;
      _secondaryColor = colors.$2;
      _originalPrimaryColor = colors.$1;
      _originalSecondaryColor = colors.$2;
    });
  }

  Future<void> _loadFollowPrimaryColorSetting() async {
    final follow = _storageDao.getBool('follow_primary_color') ?? false;
    setState(() {
      _followPrimaryColor = follow;
      if (_followPrimaryColor) {
        _updateSecondaryFromPrimary(_primaryColor);
      }
    });
  }

  Future<void> _loadCurrentNode() async {
    setState(() {
      _currentNode = _httpClient.getCurrentNode();
    });
  }

  void _updateSecondaryFromPrimary(Color primary) {
    // 生成一个基于主色调的次色调
    final hslColor = HSLColor.fromColor(primary);
    final newSecondary = hslColor
        .withLightness((hslColor.lightness + 0.1).clamp(0.0, 1.0))
        .withSaturation((hslColor.saturation - 0.1).clamp(0.0, 1.0))
        .toColor();

    _updateColors(primary, newSecondary);
  }

  void _updateColors(Color primary, Color secondary) {
    setState(() {
      _primaryColor = primary;
      _secondaryColor = _followPrimaryColor
          ? HSLColor.fromColor(primary)
              .withLightness(
                  (HSLColor.fromColor(primary).lightness + 0.1).clamp(0.0, 1.0))
              .withSaturation((HSLColor.fromColor(primary).saturation - 0.1)
                  .clamp(0.0, 1.0))
              .toColor()
          : secondary;
      _hasChanges = _primaryColor != _originalPrimaryColor ||
          _secondaryColor != _originalSecondaryColor;
    });
  }

  void _resetColors() {
    setState(() {
      _primaryColor = _originalPrimaryColor;
      _secondaryColor = _originalSecondaryColor;
      _hasChanges = false;
    });
  }

  void _restoreDefaultColors() {
    setState(() {
      _primaryColor = defaultPrimaryColor;
      _secondaryColor = defaultSecondaryColor;
      _hasChanges = _primaryColor != _originalPrimaryColor ||
          _secondaryColor != _originalSecondaryColor;
    });
  }

  void _applyChanges() {
    MyApp.of(context).updateThemeColors(_primaryColor, _secondaryColor);
    setState(() {
      _originalPrimaryColor = _primaryColor;
      _originalSecondaryColor = _secondaryColor;
      _hasChanges = false;
    });
    CustomSnackBar.show(context, message: '主题已更新');
  }

  void _toggleFollowPrimaryColor(bool value) async {
    setState(() {
      _followPrimaryColor = value;
      if (_followPrimaryColor) {
        _updateSecondaryFromPrimary(_primaryColor);
      }
    });
    await _storageDao.setBool('follow_primary_color', value);
  }

  Future<void> _switchNode(String node) async {
    await _httpClient.switchApiNode(node);
    setState(() {
      _currentNode = node;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 主题设置
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            '主题设置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (!_hasChanges)
                            TextButton.icon(
                              onPressed: _restoreDefaultColors,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white70,
                                size: 18,
                              ),
                              label: const Text(
                                '恢复默认',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          if (_hasChanges) ...[
                            TextButton(
                              onPressed: _resetColors,
                              child: const Text(
                                '取消',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _applyChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                              child: const Text('应用'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        '主色调',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      onTap: () => _showColorPicker(
                        context,
                        _primaryColor,
                        (color) => _updateColors(color, _secondaryColor),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        '次色调跟随主色调',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _followPrimaryColor,
                      onChanged: _toggleFollowPrimaryColor,
                      activeColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                    ),
                    ListTile(
                      title: const Text(
                        '次色调',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _secondaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      enabled: !_followPrimaryColor,
                      onTap: _followPrimaryColor
                          ? null
                          : () => _showColorPicker(
                                context,
                                _secondaryColor,
                                (color) => _updateColors(_primaryColor, color),
                              ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '预览效果',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primaryColor.withOpacity(0.8),
                              _secondaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '新主题预览',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 数据管理
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            '数据管理',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.download,
                        color: Colors.white,
                      ),
                      title: const Text(
                        '导出所有数据',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        '备份所有角色卡和聊天记录',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () async {
                        try {
                          // 获取服务实例
                          final prefs = await SharedPreferences.getInstance();
                          final characterCardDao = CharacterCardDao(prefs);
                          final chatHistoryDao = ChatHistoryDao(prefs);
                          final characterCardService =
                              CharacterCardService(characterCardDao, 'user123');
                          final chatHistoryService =
                              ChatHistoryService(chatHistoryDao);

                          if (mounted) {
                            // 使用加载动画并导出所有数据
                            await LoadingOverlay.show(
                              context,
                              text: '正在导出数据...',
                              future: () => ChatExportImportUtil.exportAllData(
                                context,
                                characterCardService,
                                chatHistoryService,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            CustomSnackBar.show(context, message: '导出失败: $e');
                          }
                        }
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: const Icon(
                        Icons.upload_file,
                        color: Colors.white,
                      ),
                      title: const Text(
                        '导入数据',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        '导入备份的角色卡和聊天记录',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () async {
                        // 获取ChatHistoryService实例
                        final prefs = await SharedPreferences.getInstance();
                        final chatHistoryDao = ChatHistoryDao(prefs);
                        final chatHistoryService =
                            ChatHistoryService(chatHistoryDao);

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImportPage(
                                chatHistoryService: chatHistoryService,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 账号设置
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            '账号设置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      title: const Text(
                        '修改用户名',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        '修改后需要重新登录生效',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => _showChangeUsernameDialog(context),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                      ),
                      title: const Text(
                        '修改密码',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 关于我们和免责声明
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                      ),
                      title: const Text(
                        '关于我们',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 退出登录按钮
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    '退出登录',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(context),
                ),
              ),
              // API节点设置
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'API节点',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.black.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text(
                                      '直连节点',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      _switchNode(_httpClient.getDefaultNode());
                                      Navigator.pop(context);
                                    },
                                    selected: _currentNode ==
                                        _httpClient.getDefaultNode(),
                                    selectedColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                  ListTile(
                                    title: const Text(
                                      'CDN节点',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      _switchNode(_httpClient.getCdnNode());
                                      Navigator.pop(context);
                                    },
                                    selected: _currentNode ==
                                        _httpClient.getCdnNode(),
                                    selectedColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currentNode == _httpClient.getDefaultNode()
                                      ? '直连节点'
                                      : 'CDN节点',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    CustomDialog.show(
      context: context,
      title: '选择颜色',
      child: ColorPicker(
        pickerColor: currentColor,
        onColorChanged: onColorChanged,
        pickerAreaHeightPercent: 0.8,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '确定',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    CustomDialog.show(
      context: context,
      title: '退出登录',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Icon(
            Icons.logout_rounded,
            size: 64,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          const Text(
            '确定要退出登录吗？',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _storageDao.clearUserData();
            _storageDao.clearCredentials();
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          },
          child: const Text(
            '退出',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  void _showChangeUsernameDialog(BuildContext context) {
    final controller = TextEditingController();
    CustomDialog.show(
      context: context,
      title: '修改用户名',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '请输入新用户名',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: () async {
            final username = controller.text.trim();
            if (username.isEmpty) {
              CustomSnackBar.show(context, message: '用户名不能为空');
              return;
            }
            if (username.length < 2 || username.length > 20) {
              CustomSnackBar.show(context, message: '用户名长度必须在2-20个字符之间');
              return;
            }

            Navigator.of(context).pop(); // 先关闭对话框
            final error = await _profileService.updateUsername(username);
            if (error == null) {
              // 更新本地存储的用户信息
              final userData = _storageDao.getUser();
              if (userData != null) {
                userData['user']['username'] = username;
                await _storageDao.saveUser(userData);
              }
              if (mounted) {
                CustomSnackBar.show(context, message: '用户名修改成功，重新登录后生效');
              }
            } else if (mounted) {
              CustomSnackBar.show(context, message: error);
            }
          },
          child: const Text(
            '确定',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    CustomDialog.show(
      context: context,
      title: '修改密码',
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: oldPasswordController,
              obscureText: obscureOldPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '请输入当前密码',
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureOldPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureOldPassword = !obscureOldPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: obscureNewPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '请输入新密码',
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureNewPassword = !obscureNewPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: obscureConfirmPassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '请确认新密码',
                hintStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        TextButton(
          onPressed: () async {
            final oldPassword = oldPasswordController.text.trim();
            final newPassword = newPasswordController.text.trim();
            final confirmPassword = confirmPasswordController.text.trim();

            if (oldPassword.isEmpty ||
                newPassword.isEmpty ||
                confirmPassword.isEmpty) {
              CustomSnackBar.show(context, message: '请填写所有密码字段');
              return;
            }

            if (oldPassword.length < 6 || oldPassword.length > 20) {
              CustomSnackBar.show(context, message: '原密码长度必须在6-20个字符之间');
              return;
            }

            if (newPassword.length < 6 || newPassword.length > 20) {
              CustomSnackBar.show(context, message: '新密码长度必须在6-20个字符之间');
              return;
            }

            if (newPassword != confirmPassword) {
              CustomSnackBar.show(context, message: '两次输入的新密码不一致');
              return;
            }

            Navigator.of(context).pop(); // 先关闭对话框
            final error =
                await _profileService.updatePassword(oldPassword, newPassword);
            if (error == null) {
              if (mounted) {
                CustomSnackBar.show(context, message: '密码修改成功');
                // 直接调用退出登录的逻辑
                _storageDao.clearUserData();
                _storageDao.clearCredentials();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            } else if (mounted) {
              CustomSnackBar.show(context, message: error);
            }
          },
          child: const Text(
            '确定',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
