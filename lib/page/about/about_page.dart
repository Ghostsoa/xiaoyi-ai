import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../net/admin/version_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _currentVersion = '';
  String _latestVersion = '';
  bool _hasNewVersion = false;
  final Map<String, bool> _expandedSections = {
    'about': false,
    'privacy': false,
    'disclaimer': false,
  };

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });

      final result = await VersionService.getVersionInfo();
      if (result.containsKey('current_version')) {
        setState(() {
          _latestVersion = result['current_version'] as String;
          _hasNewVersion =
              _compareVersions(_latestVersion, _currentVersion) > 0;
        });
      }
    } catch (e) {
      print('加载版本信息失败: $e');
    }
  }

  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) {
        return 1;
      } else if (v1Parts[i] < v2Parts[i]) {
        return -1;
      }
    }

    return 0;
  }

  Widget _buildVersionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '当前版本',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'v$_currentVersion',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (_latestVersion.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '最新版本',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasNewVersion) ...[
                    const Icon(
                      Icons.system_update_alt,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'v$_latestVersion',
                    style: TextStyle(
                      color: _hasNewVersion ? Colors.red : Colors.white,
                      fontSize: 16,
                      fontWeight:
                          _hasNewVersion ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String content,
    required String sectionKey,
  }) {
    final isExpanded = _expandedSections[sectionKey] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedSections[sectionKey] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // 内容区域
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题和返回按钮
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '关于小懿AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 版本信息
                    _buildVersionCard(),
                    const SizedBox(height: 24),
                    // 关于小懿AI
                    _buildExpandableSection(
                      title: '应用介绍',
                      content:
                          '小懿AI是一款专注于角色扮演的AI助手应用。我们致力于为用户提供安全、有趣、富有创意的对话体验。通过先进的AI技术，为您打造专属的虚拟角色互动空间。',
                      sectionKey: 'about',
                    ),
                    const SizedBox(height: 12),
                    // 隐私政策
                    _buildExpandableSection(
                      title: '隐私政策',
                      content:
                          '1. 信息收集\n我们仅收集必要的用户信息（如邮箱、用户名）用于账号管理和服务提供。对话内容将被加密存储，用于提供AI服务和改善用户体验。\n\n2. 信息使用\n收集的信息仅用于：\n• 提供和改进AI对话服务\n• 个性化用户体验\n• 账号管理和安全验证\n• 必要的系统通知\n\n3. 信息安全\n我们采用业界标准的加密技术保护您的个人信息和对话内容。未经您的同意，我们不会向第三方分享您的个人信息。\n\n4. 用户权利\n您有权：\n• 访问和修改您的个人信息\n• 删除您的账号和相关数据\n• 选择退出个性化服务\n• 了解您的信息使用情况\n\n5. 政策更新\n我们保留随时更新本隐私政策的权利。更新后的政策将在应用内发布，并通知用户重要变更。',
                      sectionKey: 'privacy',
                    ),
                    const SizedBox(height: 12),
                    // 免责声明
                    _buildExpandableSection(
                      title: '免责声明',
                      content:
                          '1. 本应用仅供娱乐和学习交流使用，禁止用于任何违法、违规或不当用途。\n\n2. 严禁利用本应用生成、传播任何涉及暴力、色情、歧视、政治敏感等违法违规内容。\n\n3. AI生成的内容可能存在不准确性，用户应自行判断其真实性和适用性。\n\n3. 用户在使用过程中产生的所有内容和行为均由用户本人承担全部责任。\n\n5. 如违反上述规定，我们将保留追究相关法律责任的权利。\n\n6. 我们保留随时修改本声明的权利，修改后的声明将在应用内公布。\n\n本应用的所有权利均归小懿AI所有。本声明的最终解释权归小懿AI所有。',
                      sectionKey: 'disclaimer',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
