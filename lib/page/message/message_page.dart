import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../model/chat_list_item.dart';
import '../../model/character_card.dart';
import '../../service/chat_list_service.dart';
import '../../service/character_card_service.dart';
import '../../service/chat_history_service.dart';
import '../../service/image_service.dart';
import '../../net/notification/notification_service.dart';
import '../../page/chat/chat_page.dart';
import '../../page/chat/group_chat_page.dart';
import '../../components/custom_snack_bar.dart';
import '../assistant/official_assistant_page.dart';
import '../../net/admin/version_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MessagePage extends StatefulWidget {
  final ChatListService chatListService;
  final CharacterCardService characterCardService;
  final ChatHistoryService chatHistoryService;

  const MessagePage({
    super.key,
    required this.chatListService,
    required this.characterCardService,
    required this.chatHistoryService,
  });

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> {
  List<ChatListItem>? _items;
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // 添加通知服务和未读通知数
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationCount = 0;

  // 添加版本检测相关变量
  bool _hasNewVersion = false;

  // 添加官方助手的常量
  static const String officialAssistantCode = 'official_assistant';
  final ChatListItem officialAssistant = ChatListItem(
    characterCode: officialAssistantCode,
    title: '官方助手',
    lastMessage: '有什么可以帮您的吗？',
    lastMessageTime: DateTime.now(),
    isGroup: false,
    avatarBase64: null, // 这里可以设置官方助手的头像
  );

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadNotificationStatus();
    checkVersion(); // 添加版本检测
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在页面从导航栈返回或首次加载时检查版本更新
    checkVersion();
    _loadNotificationStatus();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItems.clear();
    });
  }

  void _toggleItemSelection(String code) {
    // 不允许选择官方助手
    if (code == officialAssistantCode) return;

    setState(() {
      if (_selectedItems.contains(code)) {
        _selectedItems.remove(code);
      } else {
        _selectedItems.add(code);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    try {
      for (final code in _selectedItems) {
        await widget.chatListService.deleteItem(code);
        await widget.chatHistoryService.clearHistory(code);
      }
      _toggleSelectionMode();
      await _loadItems();
      if (mounted) {
        CustomSnackBar.show(context, message: '删除成功');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '删除失败: $e');
      }
    }
  }

  Future<void> _loadItems() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await widget.chatListService.getAllItems();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(context, message: '加载失败: $e');
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // 今天，显示时间
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天';
    } else if (difference.inDays < 7) {
      // 一周内，显示星期
      return DateFormat('EEEE', 'zh_CN').format(time);
    } else {
      // 超过一周，显示日期
      return DateFormat('MM-dd').format(time);
    }
  }

  Future<void> _onItemTap(ChatListItem item) async {
    // 处理官方助手点击
    if (item.characterCode == officialAssistantCode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OfficialAssistantPage(),
        ),
      );
      return;
    }

    try {
      final character =
          await widget.characterCardService.getCardByCode(item.characterCode);
      if (character == null) {
        if (mounted) {
          CustomSnackBar.show(context, message: '角色卡不存在');
          // 删除不存在的角色卡对应的消息列表项
          await widget.chatListService.deleteItem(item.characterCode);
          _loadItems();
        }
        return;
      }

      if (mounted) {
        if (character.chatType == ChatType.group) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatPage(
                character: character,
                chatHistoryService: widget.chatHistoryService,
                chatListService: widget.chatListService,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                character: character,
                chatHistoryService: widget.chatHistoryService,
                chatListService: widget.chatListService,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '打开对话失败: $e');
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadItems();
    await _loadNotificationStatus();
    await checkVersion(); // 添加版本检测
    _refreshController.refreshCompleted();
  }

  // 添加公开的刷新方法
  Future<void> refreshMessages() async {
    await _loadItems();
  }

  Future<void> _showSlotSelectionDialog(String characterCode) async {
    await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择存档',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future:
                    widget.chatHistoryService.getSlotPreviews(characterCode),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((preview) {
                      final slot = preview['slot'] as int;
                      final messageCount = preview['messageCount'] as int;

                      return ListTile(
                        title: Text(
                          '存档 $slot',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          messageCount > 0 ? '$messageCount条消息' : '空存档',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        onTap: () async {
                          await widget.chatHistoryService.setCurrentSlot(
                            characterCode,
                            slot,
                          );
                          if (mounted) {
                            setState(() {});
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadNotificationStatus() async {
    if (!mounted) return;

    try {
      final result = await _notificationService.getNotificationStatus();
      if (result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _unreadNotificationCount = data['unread'] as int? ?? 0;
          });
        }
      }
    } catch (e) {
      print('加载通知状态失败: $e');
    }
  }

  // 添加公开的方法，在首页切换到消息页时调用
  Future<void> checkNotificationStatus() async {
    await _loadNotificationStatus();
  }

  // 添加版本检测方法
  Future<void> checkVersion() async {
    if (!mounted) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentAppVersion = packageInfo.version;
      print('当前应用版本: $currentAppVersion');

      // 获取版本信息
      final result = await VersionService.getVersionInfo();
      print('版本检测结果: $result');

      // 检查返回的结果是否包含current_version字段
      if (result.containsKey('current_version')) {
        final latestVersion = result['current_version'] as String;
        print('最新版本: $latestVersion');

        // 正确的版本比较逻辑
        final isUpdateAvailable =
            _compareVersions(latestVersion, currentAppVersion) > 0;

        if (isUpdateAvailable) {
          if (mounted) {
            setState(() {
              _hasNewVersion = true;
            });
          }
        }
      }
    } catch (e) {
      print('检查版本失败: $e');
    }
  }

  // 比较两个版本号的大小
  // 返回值：1表示version1大于version2，0表示相等，-1表示version1小于version2
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // 确保两个版本号列表长度相同
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    // 比较各部分
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) {
        return 1;
      } else if (v1Parts[i] < v2Parts[i]) {
        return -1;
      }
    }

    return 0; // 版本号相同
  }

  // 添加打开下载链接方法
  Future<void> _openDownloadLink() async {
    final String downloadUrl = defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? 'https://xiaoyi.ink/%E5%B0%8F%E6%87%BFAI.ipa'
        : 'https://xiaoyi.ink/%E5%B0%8F%E6%87%BFAI.apk';

    final Uri url = Uri.parse(downloadUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        CustomSnackBar.show(context, message: '无法打开下载链接');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 准备显示的列表项
    final displayItems = [officialAssistant];
    if (_items != null && _items!.isNotEmpty) {
      displayItems.addAll(_items!);
    }

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
          title: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              '消息中心',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            // 版本检测图标
            if (_hasNewVersion)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.system_update,
                      color: Colors.red,
                    ),
                    tooltip: '发现新版本',
                    onPressed: _openDownloadLink,
                  ),
                  const Text(
                    "可更新",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            // 通知图标始终显示
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: '通知',
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications').then((_) {
                      // 返回后刷新通知状态
                      _loadNotificationStatus();
                    });
                  },
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (_items != null && _items!.isNotEmpty)
              if (_isSelectionMode) ...[
                TextButton(
                  onPressed: _toggleSelectionMode,
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _selectedItems.isEmpty ? null : _deleteSelectedItems,
                  child: Text(
                    '删除',
                    style: TextStyle(
                      color: _selectedItems.isEmpty
                          ? Colors.white.withOpacity(0.5)
                          : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                  onPressed: _toggleSelectionMode,
                ),
              ]
          ],
        ),
        body: SafeArea(
          child: SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            header: WaterDropHeader(
              waterDropColor: Theme.of(context).primaryColor,
              complete: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.done, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '刷新完成',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 0),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      final bool isOfficialAssistant =
                          item.characterCode == officialAssistantCode;

                      return InkWell(
                        onTap: () {
                          if (_isSelectionMode && !isOfficialAssistant) {
                            _toggleItemSelection(item.characterCode);
                          } else {
                            _onItemTap(item);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isOfficialAssistant
                                ? Colors.white.withOpacity(0.1)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_isSelectionMode && !isOfficialAssistant) ...[
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    _selectedItems.contains(item.characterCode)
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: _selectedItems
                                            .contains(item.characterCode)
                                        ? Theme.of(context).primaryColor
                                        : Colors.white.withOpacity(0.5),
                                    size: 24,
                                  ),
                                ),
                              ],
                              // 头像
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      isOfficialAssistant ? 24 : 0),
                                ),
                                child: isOfficialAssistant
                                    ? const Icon(
                                        Icons.support_agent,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : (item.avatarBase64 != null
                                        ? ImageService.imageFromBase64String(
                                            item.avatarBase64!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.person_outline,
                                            color: Colors.white54,
                                            size: 24,
                                          )),
                              ),
                              const SizedBox(width: 12),
                              // 标题和消息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.title.length > 6
                                                  ? '${item.title.substring(0, 6)}...'
                                                  : item.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (!isOfficialAssistant) ...[
                                              const SizedBox(width: 8),
                                              FutureBuilder<int>(
                                                future: widget
                                                    .chatHistoryService
                                                    .getCurrentSlot(
                                                        item.characterCode),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return const SizedBox();
                                                  }
                                                  return Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _showSlotSelectionDialog(
                                                                item.characterCode),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFF4CAF50),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color(
                                                                        0xFF4CAF50)
                                                                    .withOpacity(
                                                                        0.3),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 1),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .save_outlined,
                                                                color: Colors
                                                                    .white,
                                                                size: 12,
                                                              ),
                                                              const SizedBox(
                                                                  width: 2),
                                                              Text(
                                                                '档${snapshot.data}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: item.isGroup
                                                              ? const Color(
                                                                  0xFFFFD700)
                                                              : const Color(
                                                                  0xFF1E90FF),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: (item.isGroup
                                                                      ? const Color(
                                                                          0xFFFFD700)
                                                                      : const Color(
                                                                          0xFF1E90FF))
                                                                  .withOpacity(
                                                                      0.3),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                      0, 1),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              item.isGroup
                                                                  ? Icons
                                                                      .people_outline
                                                                  : Icons
                                                                      .person_outline,
                                                              color:
                                                                  Colors.white,
                                                              size: 12,
                                                            ),
                                                            const SizedBox(
                                                                width: 2),
                                                            Text(
                                                              item.isGroup
                                                                  ? '多人'
                                                                  : '单人',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          _formatTime(item.lastMessageTime),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.lastMessage,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
