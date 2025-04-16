import 'package:flutter/material.dart';
import 'creation_center_page.dart';
import '../../net/agent/agent_card_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _agentCardService = AgentCardService();
  bool _hasCreationPermission = false;
  bool _isLoading = true;
  String? _message;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _checkCreationQualification();
  }

  Future<void> _checkCreationQualification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _agentCardService.checkCreationQualification();
      if (mounted) {
        setState(() {
          _hasCreationPermission = result.hasPermission;
          _message = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = e.toString().replaceFirst('Exception: ', '');
        });
        CustomSnackBar.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _applyForCreationQualification() async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
    });

    try {
      final message = await LoadingOverlay.show(
        context,
        future: () => _agentCardService.applyForCreationQualification(),
        text: '申请提交中...',
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: message,
        );
        // 重新检查资格状态
        _checkCreationQualification();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );

        // 即使申请失败，也重新检查资格状态
        // 这样可以处理"已经申请过"的情况，更新UI状态
        _checkCreationQualification();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            '创作中心',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (!_isLoading && !_hasCreationPermission)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _checkCreationQualification,
              ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _hasCreationPermission
                  ? const CreationCenterPage()
                  : _buildApplyView(),
        ),
      ),
    );
  }

  Widget _buildApplyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              '创作中心需要申请权限',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '创作中心是测试版功能，允许您发布自己的大世界卡，成为创作者后，您可以创建和管理自己的AI角色卡片。',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildReasonItem(
                    icon: Icons.warning_amber_outlined,
                    title: '测试版本，功能不稳定',
                    description: '创作中心功能仍在开发测试中，可能存在不稳定性和功能变动',
                  ),
                  const SizedBox(height: 12),
                  _buildReasonItem(
                    icon: Icons.cloud_outlined,
                    title: '服务器资源有限',
                    description: '为保证系统性能，我们需要控制创作者数量，合理分配服务器资源',
                  ),
                  const SizedBox(height: 12),
                  _buildReasonItem(
                    icon: Icons.verified_outlined,
                    title: '保证内容质量',
                    description: '通过审核机制，确保平台上的创作内容符合社区规范，提供高质量体验',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isApplying ? null : _applyForCreationQualification,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isApplying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '申请创作资格',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.amber,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
