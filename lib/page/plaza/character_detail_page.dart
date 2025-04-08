import 'package:flutter/material.dart';
import '../../model/character_card.dart';
import '../../service/image_service.dart';
import '../../service/chat_history_service.dart';
import '../../components/custom_snack_bar.dart';
import '../../service/chat_list_service.dart';
import '../../model/chat_message.dart';
import '../../page/chat/chat_page.dart';
import '../../page/chat/group_chat_page.dart';
import '../../dao/storage_dao.dart';

class CharacterDetailPage extends StatefulWidget {
  final CharacterCard card;
  final ChatHistoryService chatHistoryService;
  final ChatListService chatListService;

  const CharacterDetailPage({
    super.key,
    required this.card,
    required this.chatHistoryService,
    required this.chatListService,
  });

  @override
  State<CharacterDetailPage> createState() => _CharacterDetailPageState();
}

class _CharacterDetailPageState extends State<CharacterDetailPage> {
  String? _currentUserId;
  bool _isAuthor = false;
  final _storageDao = StorageDao();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = _storageDao.getUserId();
    setState(() {
      _currentUserId = userId;
      _isAuthor = userId != null && userId == widget.card.authorId;
    });
  }

  bool get _canViewSettings {
    // 如果设定未隐藏，或者用户是作者，则可以查看设定
    return !widget.card.hideSettings || _isAuthor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          if (widget.card.backgroundImageBase64 != null)
            Positioned.fill(
              child: ImageService.imageFromBase64String(
                widget.card.backgroundImageBase64!,
                fit: BoxFit.cover,
              ),
            ),
          // 背景渐变
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          // 内容
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 头部信息：封面+标题
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左侧封面
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: widget.card.coverImageBase64 != null
                                ? ImageService.imageFromBase64String(
                                    widget.card.coverImageBase64!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.image_outlined,
                                    color: Colors.white54,
                                    size: 32,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // 右侧信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.card.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        widget.card.chatType == ChatType.single
                                            ? '单人'
                                            : '多人',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...widget.card.tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // 简介
                      const Text(
                        '简介',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.card.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 设定
                      const Text(
                        '设定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _canViewSettings
                          ? Text(
                              widget.card.setting,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        color: Colors.red.withOpacity(0.8),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '无权限查看',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '该角色卡的设定内容已被作者隐藏，只有作者可以查看。',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 24),
                      // 用户设定
                      if (widget.card.userSetting.isNotEmpty) ...[
                        const Text(
                          '用户设定',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.card.userSetting,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // 群聊角色列表
                      if (widget.card.chatType == ChatType.group &&
                          widget.card.groupCharacters.isNotEmpty) ...[
                        const Text(
                          '群聊角色',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.card.groupCharacters.map((character) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                if (character.avatarBase64 != null)
                                  ClipOval(
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: ImageService.imageFromBase64String(
                                        character.avatarBase64!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white24,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        character.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        character.setting,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              // 底部按钮
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // 开始对话按钮
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // 初始化历史记录
                            final history = await widget.chatHistoryService
                                .getHistory(widget.card.code);

                            // 如果是单人聊天且历史记录为空，且有开场白，则添加开场白作为第一条消息
                            if (widget.card.chatType == ChatType.single &&
                                history.messages.isEmpty &&
                                widget.card.openingMessage != null &&
                                widget.card.openingMessage!.isNotEmpty) {
                              history.addMessage(
                                  false, widget.card.openingMessage!);
                              await widget.chatHistoryService
                                  .saveHistory(history);
                            }

                            // 创建或更新消息列表项
                            final message = history.messages.isNotEmpty
                                ? ChatMessage(
                                    isUser:
                                        history.messages.last['role'] == 'user',
                                    content:
                                        history.messages.last['content'] ?? '',
                                    timestamp: DateTime.now(),
                                  )
                                : ChatMessage(
                                    isUser: false,
                                    content:
                                        widget.card.chatType == ChatType.single
                                            ? '开始和${widget.card.title}对话吧'
                                            : '开始群聊吧',
                                    timestamp: DateTime.now(),
                                  );

                            await widget.chatListService
                                .updateItem(widget.card, message);

                            if (widget.card.chatType == ChatType.single) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    character: widget.card,
                                    chatHistoryService:
                                        widget.chatHistoryService,
                                    chatListService: widget.chatListService,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupChatPage(
                                    character: widget.card,
                                    chatHistoryService:
                                        widget.chatHistoryService,
                                    chatListService: widget.chatListService,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            CustomSnackBar.show(context,
                                message: '初始化对话失败: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.card.chatType == ChatType.single
                              ? '开始对话'
                              : '开始群聊',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // 返回按钮
                    Container(
                      margin: const EdgeInsets.only(left: 16),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          '返回',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
