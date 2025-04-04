import 'package:flutter/material.dart';
import '../../../../net/admin/version_service.dart';
import '../../../../components/custom_snack_bar.dart';

class VersionManagePage extends StatefulWidget {
  const VersionManagePage({super.key});

  @override
  State<VersionManagePage> createState() => _VersionManagePageState();
}

class _VersionManagePageState extends State<VersionManagePage> {
  final _currentVersionController = TextEditingController();
  final _minVersionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final versionInfo = await VersionService.getVersionInfo();
      setState(() {
        _currentVersionController.text = versionInfo['current_version'] ?? '';
        _minVersionController.text = versionInfo['min_version'] ?? '';
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载版本信息失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateVersionInfo() async {
    if (_currentVersionController.text.isEmpty ||
        _minVersionController.text.isEmpty) {
      CustomSnackBar.show(context, message: '请填写完整的版本信息');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await VersionService.updateVersion(
        currentVersion: _currentVersionController.text,
        minVersion: _minVersionController.text,
      );

      if (mounted) {
        CustomSnackBar.show(context, message: '版本信息更新成功');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '更新版本信息失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update, size: 28),
              const SizedBox(width: 12),
              const Text(
                '版本管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _isLoading ? null : _loadVersionInfo,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('刷新'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前版本',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _currentVersionController,
                      decoration: const InputDecoration(
                        hintText: '例如: 1.0.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '最低支持版本',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _minVersionController,
                      decoration: const InputDecoration(
                        hintText: '例如: 1.0.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateVersionInfo,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.save, size: 18),
                      SizedBox(width: 8),
                      Text('保存版本信息'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentVersionController.dispose();
    _minVersionController.dispose();
    super.dispose();
  }
}
