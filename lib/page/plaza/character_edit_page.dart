import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/character_card.dart';
import '../../service/character_card_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../service/image_service.dart';
import '../../net/chat/chat_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';
import '../../net/chat/model_service.dart';

class CharacterEditPage extends StatefulWidget {
  final CharacterCardService characterCardService;
  final CharacterCard? card;

  const CharacterEditPage({
    super.key,
    required this.characterCardService,
    this.card,
  });

  @override
  State<CharacterEditPage> createState() => _CharacterEditPageState();
}

class _CharacterEditPageState extends State<CharacterEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _settingController;
  late final TextEditingController _userSettingController;
  late final TextEditingController _statusBarController;
  late final TextEditingController _modelNameController;
  late List<String> _tags;
  late ChatType _chatType;
  late ModelParameters _modelParams;
  late List<GroupCharacter> _groupCharacters;
  String? _coverImageBase64;
  String? _backgroundImageBase64;
  late Color _aiBubbleColor;
  late Color _aiTextColor;
  late Color _userBubbleColor;
  late Color _userTextColor;
  late double _backgroundOpacity;
  late StatusBarType _statusBarType;
  late String _modelName;
  final _modelService = ModelService();
  bool _isLoadingModels = true;
  List<ModelGroup> _modelGroups = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.card?.description ?? '');
    _settingController =
        TextEditingController(text: widget.card?.setting ?? '');
    _userSettingController =
        TextEditingController(text: widget.card?.userSetting ?? '');
    _statusBarController =
        TextEditingController(text: widget.card?.statusBar ?? '');
    _modelNameController = TextEditingController(
        text: widget.card?.modelName ?? 'gemini-2.0-flash');
    _modelName = widget.card?.modelName ?? 'gemini-2.0-flash';
    _tags = widget.card?.tags ?? [];
    _chatType = widget.card?.chatType ?? ChatType.single;
    _modelParams = widget.card?.modelParams ?? ModelParameters();
    _groupCharacters = widget.card?.groupCharacters ?? [];
    _coverImageBase64 = widget.card?.coverImageBase64;
    _backgroundImageBase64 = widget.card?.backgroundImageBase64;
    _aiBubbleColor = widget.card?.aiBubbleColor ?? const Color(0x1AFFFFFF);
    _aiTextColor = widget.card?.aiTextColor ?? const Color(0xFFFFFFFF);
    _userBubbleColor = widget.card?.userBubbleColor ?? const Color(0xE61976D2);
    _userTextColor = widget.card?.userTextColor ?? const Color(0xFFFFFFFF);
    _backgroundOpacity = widget.card?.backgroundOpacity ?? 0.0;
    _statusBarType = widget.card?.statusBarType ?? StatusBarType.none;

    // 获取可用模型列表
    _loadModelGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _settingController.dispose();
    _userSettingController.dispose();
    _statusBarController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCover) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String base64String = isCover
          ? await ImageService.processCoverImage(image.path)
          : await ImageService.processBackgroundImage(image.path);
      setState(() {
        if (isCover) {
          _coverImageBase64 = base64String;
        } else {
          _backgroundImageBase64 = base64String;
        }
      });
    }
  }

  Future<void> _saveCard() async {
    // 检查必填字段
    if (_titleController.text.trim().isEmpty) {
      CustomSnackBar.show(context, message: '请输入作品名称');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      CustomSnackBar.show(context, message: '请输入简介');
      return;
    }

    // 检查群聊角色数量
    if (_chatType == ChatType.group && _groupCharacters.length < 2) {
      CustomSnackBar.show(context, message: '群聊角色数量必须大于2个');
      return;
    }

    // 检查群聊模式下不能选择沉浸式状态栏
    if (_chatType == ChatType.group &&
        _statusBarType == StatusBarType.immersive) {
      CustomSnackBar.show(context, message: '群聊模式不支持沉浸式状态栏');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (widget.card == null) {
        // 创建新卡片
        await widget.characterCardService.createCard(
          title: _titleController.text,
          description: _descriptionController.text,
          tags: _tags,
          setting: _settingController.text,
          userSetting: _userSettingController.text,
          chatType: _chatType,
          statusBarType: _statusBarType,
          statusBar: _statusBarController.text,
          coverImageBase64: _coverImageBase64,
          backgroundImageBase64: _backgroundImageBase64,
          modelName: _modelName,
          modelParams: _modelParams,
          groupCharacters: _groupCharacters,
        );
      } else {
        // 更新现有卡片
        final updatedCard = CharacterCard(
          code: widget.card!.code,
          title: _titleController.text,
          description: _descriptionController.text,
          tags: _tags,
          setting: _settingController.text,
          userSetting: _userSettingController.text,
          chatType: _chatType,
          statusBarType: _statusBarType,
          statusBar: _statusBarController.text,
          coverImageBase64: _coverImageBase64,
          backgroundImageBase64: _backgroundImageBase64,
          modelName: _modelName,
          modelParams: _modelParams,
          groupCharacters: _groupCharacters,
          aiBubbleColor: _aiBubbleColor,
          aiTextColor: _aiTextColor,
          userBubbleColor: _userBubbleColor,
          userTextColor: _userTextColor,
          backgroundOpacity: _backgroundOpacity,
        );
        await widget.characterCardService.updateCard(updatedCard);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      CustomSnackBar.show(context, message: '保存失败: $e');
    }
  }

  Widget _buildImagePicker(bool isCover) {
    final base64String = isCover ? _coverImageBase64 : _backgroundImageBase64;
    return GestureDetector(
      onTap: () => _pickImage(isCover),
      child: Container(
        height: 100,
        color: Colors.black12,
        child: base64String != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ImageService.imageFromBase64String(
                    base64String,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _pickImage(isCover),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCover ? Icons.add_photo_alternate : Icons.wallpaper,
                    color: Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCover ? '添加封面图' : '添加背景图',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int? maxLines,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 2,
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            errorStyle: TextStyle(color: Colors.redAccent),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '请输入$label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '标签',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 2,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () async {
                final tag = await showDialog<String>(
                  context: context,
                  builder: (context) => _AddTagDialog(),
                );
                if (tag != null && tag.isNotEmpty) {
                  setState(() {
                    _tags.add(tag);
                  });
                }
              },
            ),
          ],
        ),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return IntrinsicWidth(
                child: Container(
                  height: 28,
                  color: Colors.white10,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildChatType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '聊天类型',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 2,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<ChatType>(
            value: _chatType,
            dropdownColor: Theme.of(context).primaryColor.withOpacity(0.9),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            items: ChatType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type == ChatType.single ? '单人聊天' : '群聊',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _chatType = value;
                  // 如果切换到群聊模式且当前是沉浸式状态栏，则自动切换到自定义模式
                  if (value == ChatType.group &&
                      _statusBarType == StatusBarType.immersive) {
                    _statusBarType = StatusBarType.custom;
                    _statusBarController.text = '';
                  }
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCharacters() {
    if (_chatType != ChatType.group) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '群聊角色',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 2,
              ),
            ),
            if (_groupCharacters.length < 5)
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => _showAddCharacterDialog(),
              ),
          ],
        ),
        if (_groupCharacters.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: const Text(
              '点击右上角添加群聊角色（最多5个）',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groupCharacters.length,
            itemBuilder: (context, index) {
              final character = _groupCharacters[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                ),
                child: ListTile(
                  leading: character.avatarBase64 != null
                      ? ClipOval(
                          child: ImageService.imageFromBase64String(
                            character.avatarBase64!,
                            width: 40,
                            height: 40,
                          ),
                        )
                      : const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                  title: Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    character.setting,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _groupCharacters.removeAt(index);
                      });
                    },
                  ),
                  onTap: () => _showAddCharacterDialog(
                    editIndex: index,
                    character: character,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showAddCharacterDialog({
    int? editIndex,
    GroupCharacter? character,
  }) async {
    final result = await Navigator.of(context).push<GroupCharacter>(
      MaterialPageRoute(
        builder: (context) => GroupCharacterEditPage(
          character: character,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (editIndex != null) {
          _groupCharacters[editIndex] = result;
        } else {
          _groupCharacters.add(result);
        }
      });
    }
  }

  Widget _buildStatusBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '状态栏设置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 2,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  label: const Text(
                    '必读',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).primaryColor,
                        title: const Text(
                          '状态栏必读',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          '状态栏必须使用标准的JSON格式才能生效。如果不会编写JSON，请使用AI生成功能。\n\n错误示例：\n普通文本\n随意的键值对\n\n正确示例：\n{\n  "生命值": "num",\n  "状态": "text",\n  "装备": "text"\n}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              '知道了',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            if (_statusBarType == StatusBarType.custom ||
                _statusBarType == StatusBarType.immersive)
              TextButton.icon(
                onPressed: () => _showGenerateStatusBarDialog(),
                icon: const Icon(Icons.auto_awesome,
                    color: Colors.white70, size: 16),
                label: const Text(
                  'AI生成',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<StatusBarType>(
            value: _statusBarType,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Theme.of(context).primaryColor.withOpacity(0.9),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            items: [
              const DropdownMenuItem(
                value: StatusBarType.none,
                child: Text('不启用', style: TextStyle(color: Colors.white)),
              ),
              if (_chatType != ChatType.group)
                const DropdownMenuItem(
                  value: StatusBarType.immersive,
                  child: Text('沉浸式', style: TextStyle(color: Colors.white)),
                ),
              const DropdownMenuItem(
                value: StatusBarType.custom,
                child: Text('自定义', style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _statusBarType = value!;
                // 如果切换到沉浸式，设置内置的固定内容
                if (value == StatusBarType.immersive) {
                  _statusBarController.text = '''
        {
        "system_prompt": "系统提示(可选),比如获得什么,获取什么,失去什么",
         "next_actions": [
          {
              "选项1": "行动选项1"
          },
          {
              "选项2": "行动选项2"
          },
          {
              "选项3": "行动选项3"
          }
        ],
        "character": {
            "name": "角色名称",
            "basic_status": {
                "health": "状态值(0-100)",
                "energy": "能量值(0-100)",
                "mood": "情绪状态"
            },
            "attributes": {
                "main_attribute": "主属性(修为/侦查力/解密能力/职业技能)",
                "sub_attributes": ["次要属性1", "次要属性2"]
            },
            "skills": {
                "basic_skills": ["基础技能"],
                "special_skills": ["特殊技能"],
                "potential_skills": ["潜在技能"]
            },
            "appearance": "外表特征",
            "identity": {
                "main_identity": "主要身份",
                "special_identity": "特殊身份",
                "reputation": "声望/威望"
            }
        },
        "inventory": {
            "背包": {
                "common_items": ["常用物品"],
                "special_items": ["特殊物品"],
                "key_items": ["关键物品"]
            },
            "装备": {
                "main_equipment": ["主要装备"],
                "secondary_equipment": ["辅助装备"],
                "special_equipment": ["特殊装备"]
            },
            "resources": {
                "main_resource": "主要资源",
                "sub_resources": ["次要资源"],
                "special_resources": ["特殊资源"]
            }
        },
        "quests": {
            "main_quest": {
                "title": "主要目标",
                "description": "详细描述",
                "progress": "进度值",
                "rewards": ["可能的奖励"]
            },
            "side_quests": [
                {
                    "title": "支线目标",
                    "description": "描述",
                    "progress": "进度值"
                }
            ],
            "hidden_quests": ["隐藏任务"],
            "obstacles": {
                "current": ["当前障碍"],
                "potential": ["潜在障碍"],
                "special": ["特殊挑战"]
            }
        },
        "relationships": {
            "core_relations": {
                "allies": ["盟友/友好关系"],
                "enemies": ["敌对关系"],
                "neutral": ["中立关系"]
            },
            "special_relations": ["特殊关系"],
            "organization_relations": {
                "friendly": ["友好组织"],
                "hostile": ["敌对组织"],
                "neutral": ["中立组织"]
            }
        },
        "environment": {
            "location": {
                "main_location": "主要位置",
                "sub_locations": ["相关位置"],
                "special_locations": ["特殊地点"]
            },
            "time": {
                "current_time": "当前时间",
                "time_limit": "时间限制(如果有)",
                "special_time": "特殊时间点"
            },
            "conditions": {
                "weather": "天气状况",
                "atmosphere": "环境氛围",
                "special_effects": ["特殊环境效果"]
            }
        },
        "status_effects": {
            "buffs": ["有利状态"],
            "debuffs": ["不利状态"],
            "special_effects": ["特殊状态"]
        }
    }
                    ''';
                } else if (value == StatusBarType.custom) {
                  // 切换到自定义时，清空内容
                  _statusBarController.text = '';
                } else {
                  // 切换到不启用时，清空内容
                  _statusBarController.text = '';
                }
              });
            },
          ),
        ),
        if (_statusBarType == StatusBarType.custom) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _statusBarController,
            style: const TextStyle(color: Colors.white),
            maxLines: null,
            decoration: const InputDecoration(
              labelText: '状态栏内容',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            validator: (value) {
              if (_statusBarType == StatusBarType.custom &&
                  (value == null || value.isEmpty)) {
                return '请输入状态栏内容';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Future<void> _showGenerateStatusBarDialog() async {
    final promptController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI生成状态栏',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: promptController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '描述你想要的状态栏，比如"我需要状态、衣着、装备状态栏"',
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () async {
                      if (promptController.text.isEmpty) {
                        CustomSnackBar.show(context, message: '请输入描述');
                        return;
                      }
                      Navigator.of(context).pop(promptController.text);
                    },
                    child: const Text(
                      '生成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        final chatService = ChatService();
        final statusBar = await LoadingOverlay.show(
          context,
          future: () => chatService.generateStatusBar(result),
        );
        if (statusBar != null && mounted) {
          setState(() {
            _statusBarController.text = statusBar;
          });
        }
      } catch (e) {
        CustomSnackBar.show(context, message: '生成失败: $e');
      }
    }
  }

  Widget _buildModelParams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '模型参数',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 2,
              ),
            ),
            if (_isLoadingModels)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              IconButton(
                icon:
                    const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: _loadModelGroups,
                tooltip: '刷新模型列表',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isLoadingModels
              ? const SizedBox(
                  height: 48,
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))))
              : _errorMessage.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade300, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '加载模型列表失败，使用默认模型',
                              style: TextStyle(
                                  color: Colors.red.shade300, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildModelDropdown(),
        ),
        const SizedBox(height: 24),
        _buildSlider(
          label: '温度',
          value: _modelParams.temperature,
          description: '控制回复的随机性，值越高回复越多样化，值越低回复越确定',
          onChanged: (value) {
            setState(() {
              _modelParams = ModelParameters(
                temperature: value,
                topP: _modelParams.topP,
                presencePenalty: _modelParams.presencePenalty,
                frequencyPenalty: _modelParams.frequencyPenalty,
                maxTokens: _modelParams.maxTokens,
                enableContextLimit: _modelParams.enableContextLimit,
                contextTurns: _modelParams.contextTurns,
              );
            });
          },
        ),
        _buildSlider(
          label: '采样范围',
          value: _modelParams.topP,
          description: '控制词汇生成多样性，较高值会考虑更多可能性，较低值更保守',
          onChanged: (value) {
            setState(() {
              _modelParams = ModelParameters(
                temperature: _modelParams.temperature,
                topP: value,
                presencePenalty: _modelParams.presencePenalty,
                frequencyPenalty: _modelParams.frequencyPenalty,
                maxTokens: _modelParams.maxTokens,
                enableContextLimit: _modelParams.enableContextLimit,
                contextTurns: _modelParams.contextTurns,
              );
            });
          },
        ),
        _buildSlider(
          label: '存在惩罚',
          value: _modelParams.presencePenalty,
          description: '降低模型重复已出现主题的可能性，值越高越避免重复内容',
          onChanged: (value) {
            setState(() {
              _modelParams = ModelParameters(
                temperature: _modelParams.temperature,
                topP: _modelParams.topP,
                presencePenalty: value,
                frequencyPenalty: _modelParams.frequencyPenalty,
                maxTokens: _modelParams.maxTokens,
                enableContextLimit: _modelParams.enableContextLimit,
                contextTurns: _modelParams.contextTurns,
              );
            });
          },
        ),
        _buildSlider(
          label: '频率惩罚',
          value: _modelParams.frequencyPenalty,
          description: '降低模型重复使用相同词汇的可能性，值越高表达越多样',
          onChanged: (value) {
            setState(() {
              _modelParams = ModelParameters(
                temperature: _modelParams.temperature,
                topP: _modelParams.topP,
                presencePenalty: _modelParams.presencePenalty,
                frequencyPenalty: value,
                maxTokens: _modelParams.maxTokens,
                enableContextLimit: _modelParams.enableContextLimit,
                contextTurns: _modelParams.contextTurns,
              );
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '最大令牌数',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _modelParams.maxTokens.toString(),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (value) {
                  final tokens = int.tryParse(value) ?? 4096;
                  setState(() {
                    _modelParams = ModelParameters(
                      temperature: _modelParams.temperature,
                      topP: _modelParams.topP,
                      presencePenalty: _modelParams.presencePenalty,
                      frequencyPenalty: _modelParams.frequencyPenalty,
                      maxTokens: tokens,
                      enableContextLimit: _modelParams.enableContextLimit,
                      contextTurns: _modelParams.contextTurns,
                    );
                  });
                },
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Text(
            '限制模型生成回复的最大长度，较大值允许更长回复但消耗更多算力',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              '上下文限制',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: _modelParams.enableContextLimit,
              onChanged: (value) {
                setState(() {
                  _modelParams = ModelParameters(
                    temperature: _modelParams.temperature,
                    topP: _modelParams.topP,
                    presencePenalty: _modelParams.presencePenalty,
                    frequencyPenalty: _modelParams.frequencyPenalty,
                    maxTokens: _modelParams.maxTokens,
                    enableContextLimit: value,
                    contextTurns: _modelParams.contextTurns,
                  );
                });
              },
              activeColor: Colors.white,
              inactiveTrackColor: Colors.white24,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Text(
            '限制对话历史记忆轮数，可减少模型混淆并节省资源，但会遗忘早期对话',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        if (_modelParams.enableContextLimit) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '记忆轮数',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _modelParams.contextTurns.toString(),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) {
                    final turns = int.tryParse(value) ?? 10;
                    setState(() {
                      _modelParams = ModelParameters(
                        temperature: _modelParams.temperature,
                        topP: _modelParams.topP,
                        presencePenalty: _modelParams.presencePenalty,
                        frequencyPenalty: _modelParams.frequencyPenalty,
                        maxTokens: _modelParams.maxTokens,
                        enableContextLimit: _modelParams.enableContextLimit,
                        contextTurns: turns,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              '模型将仅记住最近的N轮对话，较小值可提高性能但会限制长期记忆能力',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModelDropdown() {
    // 准备下拉列表项，按照组分类
    List<DropdownMenuItem<String>> items = [];

    if (_modelGroups.isEmpty) {
      // 如果没有可用模型，显示提示信息并使用默认模型
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '无可用模型，使用默认模型: $_modelName',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    for (var group in _modelGroups) {
      // 添加组标题（不可选择的项）
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: '${group.name}_header', // 仅用于唯一键，不会实际被选中
          child: Text(
            '${group.name} - ${group.comment}',
            style: TextStyle(
              color: Colors.amber.shade300,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // 添加组内的模型
      for (var model in group.models) {
        items.add(
          DropdownMenuItem<String>(
            value: model,
            child: Text(
              '  $model',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      // 添加分隔符（如果不是最后一组）
      if (group != _modelGroups.last) {
        items.add(
          DropdownMenuItem<String>(
            enabled: false,
            value: '${group.name}_divider', // 仅用于唯一键
            child: const Divider(color: Colors.white24),
          ),
        );
      }
    }

    // 确保所选模型在可选项中
    bool modelInList =
        items.any((item) => item.value == _modelName && item.enabled != false);
    String selectedValue = modelInList
        ? _modelName
        : items.firstWhere((item) => item.enabled != false).value!;

    if (!modelInList) {
      // 更新当前选中的模型
      setState(() {
        _modelName = selectedValue;
        _modelNameController.text = selectedValue;
      });
    }

    return DropdownButtonFormField<String>(
      value: selectedValue,
      style: const TextStyle(color: Colors.white),
      dropdownColor: Theme.of(context).primaryColor.withOpacity(0.9),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      items: items,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _modelName = value;
            _modelNameController.text = value;
          });
        }
      },
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white12,
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 2.0,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildChatStyleSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '聊天界面样式',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'AI气泡颜色',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) => ColorPickerDialog(
                    initialColor: _aiBubbleColor,
                    title: 'AI气泡颜色',
                  ),
                );
                if (color != null) {
                  setState(() {
                    _aiBubbleColor = color;
                  });
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _aiBubbleColor,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'AI文字颜色',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) => ColorPickerDialog(
                    initialColor: _aiTextColor,
                    title: 'AI文字颜色',
                  ),
                );
                if (color != null) {
                  setState(() {
                    _aiTextColor = color;
                  });
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _aiTextColor,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              '用户气泡颜色',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) => ColorPickerDialog(
                    initialColor: _userBubbleColor,
                    title: '用户气泡颜色',
                  ),
                );
                if (color != null) {
                  setState(() {
                    _userBubbleColor = color;
                  });
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _userBubbleColor,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              '用户文字颜色',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) => ColorPickerDialog(
                    initialColor: _userTextColor,
                    title: '用户文字颜色',
                  ),
                );
                if (color != null) {
                  setState(() {
                    _userTextColor = color;
                  });
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _userTextColor,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '背景透明度',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(_backgroundOpacity * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white12,
                trackHeight: 2,
              ),
              child: Slider(
                value: _backgroundOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                onChanged: (value) {
                  setState(() {
                    _backgroundOpacity = value;
                  });
                },
              ),
            ),
          ],
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
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.card == null ? '创建角色卡' : '编辑角色卡',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saveCard,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildImagePicker(true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImagePicker(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: '作品名称',
                controller: _titleController,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: '简介',
                controller: _descriptionController,
                maxLines: 3,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildTags(),
              const SizedBox(height: 16),
              _buildTextField(
                label: '设定',
                controller: _settingController,
                maxLines: null,
                isRequired: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: '用户设定',
                controller: _userSettingController,
                maxLines: null,
              ),
              const SizedBox(height: 16),
              _buildChatType(),
              const SizedBox(height: 16),
              _buildGroupCharacters(),
              const SizedBox(height: 16),
              _buildStatusBar(),
              const SizedBox(height: 16),
              _buildModelParams(),
              const SizedBox(height: 16),
              _buildChatStyleSettings(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 加载模型列表
  Future<void> _loadModelGroups() async {
    try {
      setState(() {
        _isLoadingModels = true;
      });

      final modelGroups = await _modelService.getAvailableModels();

      setState(() {
        _modelGroups = modelGroups;
        _isLoadingModels = false;

        // 如果当前选择的模型在可用模型列表中，则保持选择状态，否则选择列表中的第一个模型
        bool modelFound = false;
        for (var group in _modelGroups) {
          if (group.models.contains(_modelName)) {
            modelFound = true;
            break;
          }
        }

        if (!modelFound &&
            _modelGroups.isNotEmpty &&
            _modelGroups[0].models.isNotEmpty) {
          _modelName = _modelGroups[0].models[0];
          _modelNameController.text = _modelName;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingModels = false;
      });
      if (mounted) {
        CustomSnackBar.show(context, message: '获取模型列表失败: $e');
      }
    }
  }
}

class _AddTagDialog extends StatelessWidget {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '添加标签',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '输入标签名称',
                hintStyle: TextStyle(color: Colors.white70),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  child: const Text(
                    '添加',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GroupCharacterEditPage extends StatefulWidget {
  final GroupCharacter? character;

  const GroupCharacterEditPage({
    super.key,
    this.character,
  });

  @override
  State<GroupCharacterEditPage> createState() => _GroupCharacterEditPageState();
}

class _GroupCharacterEditPageState extends State<GroupCharacterEditPage> {
  final _nameController = TextEditingController();
  final _settingController = TextEditingController();
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.character?.name ?? '';
    _settingController.text = widget.character?.setting ?? '';
    _avatarBase64 = widget.character?.avatarBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _settingController.dispose();
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
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.character != null ? '编辑角色' : '添加角色',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_nameController.text.isEmpty ||
                    _settingController.text.isEmpty) {
                  CustomSnackBar.show(context, message: '请填写完整信息');
                  return;
                }
                Navigator.of(context).pop(
                  GroupCharacter(
                    avatarBase64: _avatarBase64,
                    name: _nameController.text,
                    setting: _settingController.text,
                  ),
                );
              },
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final String base64String =
                      await ImageService.processAvatarImage(image.path);
                  setState(() {
                    _avatarBase64 = base64String;
                  });
                }
              },
              child: Center(
                child: _avatarBase64 != null
                    ? Stack(
                        children: [
                          ClipOval(
                            child: ImageService.imageFromBase64String(
                              _avatarBase64!,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '角色名称',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 2,
                  ),
                ),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '角色设定',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 2,
                  ),
                ),
                TextField(
                  controller: _settingController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.title,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              displayThumbColor: true,
              portraitOnly: true,
              colorPickerWidth: 300,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: true,
              showLabel: false,
              hexInputBar: false,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selectedColor),
                  child: const Text(
                    '确定',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
