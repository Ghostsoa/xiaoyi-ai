import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../model/chat_list_item.dart';
import '../../model/character_card.dart';
import '../../service/chat_list_service.dart';
import '../../service/character_card_service.dart';
import '../../service/chat_history_service.dart';
import '../../service/image_service.dart';
import '../../page/chat/chat_page.dart';
import '../../page/chat/group_chat_page.dart';
import '../../components/custom_snack_bar.dart';
import '../assistant/official_assistant_page.dart';
import 'package:intl/date_symbol_data_local.dart';

class LocalMessagePage extends StatefulWidget {
  final ChatListService chatListService;
  final CharacterCardService characterCardService;
  final ChatHistoryService chatHistoryService;

  const LocalMessagePage({
    super.key,
    required this.chatListService,
    required this.characterCardService,
    required this.chatHistoryService,
  });

  @override
  State<LocalMessagePage> createState() => LocalMessagePageState();
}

class LocalMessagePageState extends State<LocalMessagePage> {
  List<ChatListItem>? _items;
  bool _isLoading = true;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // 添加官方助手的常量
  static const String officialAssistantCode = 'official_assistant';
  final ChatListItem officialAssistant = ChatListItem(
    characterCode: officialAssistantCode,
    title: '官方助手',
    lastMessage: '有什么可以帮您的吗？',
    lastMessageTime: DateTime.now(),
    isGroup: false,
    avatarBase64: null,
  );

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('zh_CN', null);
    _loadItems();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
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

  Future<void> _onRefresh() async {
    await _loadItems();
    _refreshController.refreshCompleted();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'zh_CN').format(time);
    } else {
      return DateFormat('MM-dd').format(time);
    }
  }

  Future<void> _onItemTap(ChatListItem item) async {
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

  @override
  Widget build(BuildContext context) {
    final displayItems = <ChatListItem>[officialAssistant];
    if (_items != null && _items!.isNotEmpty) {
      displayItems.addAll(_items!);
    }

    return SmartRefresher(
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
                  onTap: () => _onItemTap(item),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.title.length > 6
                                              ? '${item.title.substring(0, 6)}...'
                                              : item.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isOfficialAssistant) ...[
                                        const SizedBox(width: 8),
                                        FutureBuilder<int>(
                                          future: widget.chatHistoryService
                                              .getCurrentSlot(
                                                  item.characterCode),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const SizedBox();
                                            }
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showSlotSelectionDialog(
                                                          item.characterCode),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF4CAF50),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                                  0xFF4CAF50)
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.save_outlined,
                                                          color: Colors.white,
                                                          size: 12,
                                                        ),
                                                        const SizedBox(
                                                            width: 2),
                                                        Text(
                                                          '档${snapshot.data}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: item.isGroup
                                                        ? const Color(
                                                            0xFFFFD700)
                                                        : const Color(
                                                            0xFF1E90FF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (item.isGroup
                                                                ? const Color(
                                                                    0xFFFFD700)
                                                                : const Color(
                                                                    0xFF1E90FF))
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.people_outline,
                                                        color: Colors.white,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        item.isGroup
                                                            ? '多人'
                                                            : '单人',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                      color: Colors.white.withOpacity(0.5),
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
    );
  }
}
