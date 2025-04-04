import 'package:flutter/material.dart';
import 'dart:convert';

class ImmersiveStatusBar extends StatefulWidget {
  final String content;
  final Color textColor;
  final Function(String)? onActionSelected;

  const ImmersiveStatusBar({
    super.key,
    required this.content,
    required this.textColor,
    this.onActionSelected,
  });

  @override
  State<ImmersiveStatusBar> createState() => _ImmersiveStatusBarState();
}

class _ImmersiveStatusBarState extends State<ImmersiveStatusBar>
    with SingleTickerProviderStateMixin {
  bool _showStatus = false;
  Map<String, dynamic>? _statusData;
  late TabController _tabController;
  final List<String> _tabs = ['角色', '物品', '任务', '关系', '环境', '状态'];

  // 添加键名映射
  final Map<String, String> _keyMapping = {
    '角色': 'character',
    '物品': 'inventory',
    '任务': 'quests',
    '关系': 'relationships',
    '环境': 'environment',
    '状态': 'status_effects',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _parseContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ImmersiveStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _parseContent();
    }
  }

  void _parseContent() {
    try {
      _statusData = json.decode(widget.content) as Map<String, dynamic>;
    } catch (e) {
      _statusData = null;
    }
  }

  dynamic _getDataForTab(String tab) {
    if (_statusData == null) return null;

    final key = _keyMapping[tab];
    if (key == null) return null;

    final data = _statusData![key];
    if (data == null) return null;

    if (tab == '角色') {
      final Map<String, dynamic> characterData = {};
      if (data['name'] != null) {
        characterData['名称'] = data['name'];
      }
      if (data['basic_status'] is Map) {
        characterData['基础状态'] = {
          '生命值': data['basic_status']['health'],
          '能量值': data['basic_status']['energy'],
          '情绪状态': data['basic_status']['mood']
        };
      }
      if (data['attributes'] is Map) {
        characterData['属性'] = {
          '主属性': data['attributes']['main_attribute'],
          '次要属性': data['attributes']['sub_attributes']
        };
      }
      if (data['skills'] is Map) {
        characterData['技能'] = {
          '基础技能': data['skills']['basic_skills'],
          '特殊技能': data['skills']['special_skills'],
          '潜在技能': data['skills']['potential_skills']
        };
      }
      if (data['appearance'] != null) {
        characterData['外表'] = data['appearance'];
      }
      if (data['identity'] is Map) {
        characterData['身份'] = {
          '主要身份': data['identity']['main_identity'],
          '特殊身份': data['identity']['special_identity'],
          '声望': data['identity']['reputation']
        };
      }
      return characterData;
    } else if (tab == '物品') {
      final Map<String, dynamic> inventoryData = {};
      if (data['背包'] is Map) {
        inventoryData['背包'] = {
          '常用物品': data['背包']['common_items'],
          '特殊物品': data['背包']['special_items'],
          '关键物品': data['背包']['key_items']
        };
      }
      if (data['装备'] is Map) {
        inventoryData['装备'] = {
          '主要装备': data['装备']['main_equipment'],
          '辅助装备': data['装备']['secondary_equipment'],
          '特殊装备': data['装备']['special_equipment']
        };
      }
      if (data['resources'] is Map) {
        inventoryData['资源'] = {
          '主要资源': data['resources']['main_resource'],
          '次要资源': data['resources']['sub_resources'],
          '特殊资源': data['resources']['special_resources']
        };
      }
      return inventoryData;
    } else if (tab == '任务') {
      final Map<String, dynamic> questData = {};
      if (data['main_quest'] is Map) {
        questData['主线任务'] = {
          '标题': data['main_quest']['title'],
          '描述': data['main_quest']['description'],
          '进度': data['main_quest']['progress'],
          '奖励': data['main_quest']['rewards']
        };
      }
      if (data['side_quests'] is List) {
        final sideQuests = (data['side_quests'] as List)
            .map((quest) {
              if (quest is Map) {
                return {
                  '标题': quest['title'],
                  '描述': quest['description'],
                  '进度': quest['progress'],
                };
              }
              return null;
            })
            .where((quest) => quest != null)
            .toList();
        if (sideQuests.isNotEmpty) {
          questData['支线任务'] = sideQuests;
        }
      }
      if (data['hidden_quests'] is List) {
        final hiddenQuests = (data['hidden_quests'] as List)
            .map((quest) {
              if (quest is Map) {
                return {
                  '标题': quest['title'],
                  '描述': quest['description'],
                  '进度': quest['progress'],
                };
              } else if (quest is String) {
                return {'任务': quest};
              }
              return null;
            })
            .where((quest) => quest != null)
            .toList();
        if (hiddenQuests.isNotEmpty) {
          questData['隐藏任务'] = hiddenQuests;
        }
      }
      if (data['obstacles'] is Map) {
        questData['障碍'] = {
          '当前': data['obstacles']['current'],
          '潜在': data['obstacles']['potential'],
          '特殊': data['obstacles']['special']
        };
      }
      return questData;
    } else if (tab == '关系') {
      final Map<String, dynamic> relationData = {};
      if (data['core_relations'] is Map) {
        relationData['核心关系'] = {
          '盟友': data['core_relations']['allies'],
          '敌对': data['core_relations']['enemies'],
          '中立': data['core_relations']['neutral']
        };
      }
      if (data['special_relations'] is List) {
        relationData['特殊关系'] = data['special_relations'];
      }
      if (data['organization_relations'] is Map) {
        relationData['组织关系'] = {
          '友好': data['organization_relations']['friendly'],
          '敌对': data['organization_relations']['hostile'],
          '中立': data['organization_relations']['neutral']
        };
      }
      return relationData;
    } else if (tab == '环境') {
      final Map<String, dynamic> envData = {};
      if (data['location'] is Map) {
        envData['位置'] = {
          '主要位置': data['location']['main_location'],
          '相关位置': data['location']['sub_locations'],
          '特殊地点': data['location']['special_locations']
        };
      }
      if (data['time'] is Map) {
        envData['时间'] = {
          '当前时间': data['time']['current_time'],
          '时间限制': data['time']['time_limit'],
          '特殊时间点': data['time']['special_time']
        };
      }
      if (data['conditions'] is Map) {
        envData['环境条件'] = {
          '天气状况': data['conditions']['weather'],
          '环境氛围': data['conditions']['atmosphere'],
          '特殊效果': data['conditions']['special_effects']
        };
      }
      return envData;
    } else if (tab == '状态') {
      final Map<String, dynamic> statusData = {};
      if (data['buffs'] is List) {
        statusData['增益效果'] = data['buffs'];
      }
      if (data['debuffs'] is List) {
        statusData['减益效果'] = data['debuffs'];
      }
      if (data['special_effects'] is List) {
        statusData['特殊效果'] = data['special_effects'];
      }
      return statusData;
    }

    return data is Map ? data : {'内容': data.toString()};
  }

  Widget _buildDataItem(String label, dynamic value, {bool isSubItem = false}) {
    if (value == null) return const SizedBox.shrink();

    if (value is List) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSubItem)
            Text(
              label,
              style: TextStyle(
                color: widget.textColor.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: isSubItem ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: value.map((item) {
                if (item is Map) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.textColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}：',
                                style: TextStyle(
                                  color: widget.textColor.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value?.toString() ?? '',
                                  style: TextStyle(
                                    color: widget.textColor.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.toString(),
                      style: TextStyle(
                        color: widget.textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  );
                }
              }).toList(),
            ),
          ),
        ],
      );
    } else if (value is Map) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSubItem)
            Text(
              label,
              style: TextStyle(
                color: widget.textColor.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: isSubItem ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: value.entries.map((entry) {
                return _buildDataItem(entry.key, entry.value, isSubItem: true);
              }).toList(),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isSubItem ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：',
            style: TextStyle(
              color: widget.textColor.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: widget.textColor.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String tab) {
    final data = _getDataForTab(tab);
    if (data == null) {
      return Center(
        child: Text(
          '暂无$tab信息',
          style: TextStyle(
            color: widget.textColor.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map<Widget>((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDataItem(entry.key, entry.value),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_statusData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 系统提示
        if (_statusData!['system_prompt'] != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  size: 14,
                  color: Colors.amber.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusData!['system_prompt'].toString(),
                    style: TextStyle(
                      color: Colors.amber.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 状态栏切换按钮
        GestureDetector(
          onTap: () {
            setState(() {
              _showStatus = !_showStatus;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showStatus
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: widget.textColor.withOpacity(0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '状态信息',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // 状态信息内容
        if (_showStatus) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.textColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  indicatorPadding: EdgeInsets.zero,
                  labelColor: widget.textColor,
                  unselectedLabelColor: widget.textColor.withOpacity(0.5),
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  indicatorColor: widget.textColor,
                  indicatorWeight: 1,
                  tabs: _tabs
                      .map((tab) => Tab(
                            text: tab,
                            height: 35,
                          ))
                      .toList(),
                ),
                SizedBox(
                  height: 240,
                  child: TabBarView(
                    controller: _tabController,
                    children:
                        _tabs.map((tab) => _buildTabContent(tab)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 下一步行动 - 仅在状态栏折叠时显示
        if (!_showStatus &&
            _statusData!['next_actions'] != null &&
            _statusData!['next_actions'] is List) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.textColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: widget.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '下一步行动',
                      style: TextStyle(
                        color: widget.textColor.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children:
                      (_statusData!['next_actions'] as List).map((action) {
                    if (action is Map) {
                      final entry = action.entries.first;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  widget.onActionSelected?.call(entry.key);
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.textColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: widget.textColor.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.subdirectory_arrow_right,
                                    size: 14,
                                    color: widget.textColor.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        color:
                                            widget.textColor.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
