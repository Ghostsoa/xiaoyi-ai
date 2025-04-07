import 'package:flutter/material.dart';
import '../../model/character_card.dart';
import '../../net/chat/chat_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';

class StatusBarEditor extends StatelessWidget {
  final StatusBarType value;
  final ValueChanged<StatusBarType?> onChanged;
  final TextEditingController controller;
  final ChatType chatType;

  const StatusBarEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.controller,
    required this.chatType,
  });

  @override
  Widget build(BuildContext context) {
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
            if (value == StatusBarType.custom ||
                value == StatusBarType.immersive)
              TextButton.icon(
                onPressed: () => _showGenerateStatusBarDialog(context),
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
            value: value,
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
              if (chatType != ChatType.group)
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
              if (value != null) {
                onChanged(value);
                // 如果切换到沉浸式，设置内置的固定内容
                if (value == StatusBarType.immersive) {
                  controller.text = '''
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
                } else {
                  // 切换到其他类型时，清空内容
                  controller.text = '';
                }
              }
            },
          ),
        ),
        if (value == StatusBarType.custom) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
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
              if (value == null || value.isEmpty) {
                return '请输入状态栏内容';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Future<void> _showGenerateStatusBarDialog(BuildContext context) async {
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
        if (statusBar != null && context.mounted) {
          controller.text = statusBar;
        }
      } catch (e) {
        CustomSnackBar.show(context, message: '生成失败: $e');
      }
    }
  }
}
