import 'package:flutter/material.dart';
import '../profile/sponsor_page.dart';
import 'service_assistant_page.dart';

class OfficialAssistantPage extends StatelessWidget {
  const OfficialAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            // 顶部AppBar
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.support_agent, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '官方助手',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 内容区域
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 常见问题卡片
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '常见问题',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white10),
                        _buildExpandableFAQ(
                          '状态栏怎么失效了？',
                          '啊哦，状态栏罢工了？让我们来看看：\n\n1. 沉浸式状态栏\n• 试试重新发个消息，说不定它只是在打盹\n• 检查一下网络，可能是信号君偷懒去度假了\n• 如果它还是不听话，就让我们的客服来收服它吧\n\n2. 自定义状态栏\n• 确保你的 JSON 格式标准得像强迫症一样\n• 记得用标准的键值对，比如 {"mood": "happy"}\n• 仔细检查有没有多余的符号，它们就像调皮的小精灵一样容易捣乱',
                        ),
                        _buildExpandableFAQ(
                          '可以更改主题的渐变颜色吗？',
                          '当然可以！点击个人页面的设置按钮，就能找到调色盘啦。快来把界面打扮得像彩虹糖一样绚丽多彩吧！🌈',
                        ),
                        _buildExpandableFAQ(
                          '为什么对话没有回应？',
                          '让我们来查查是什么让AI小助手变得沉默寡言：\n\n1. 模型可能在思考人生（设定问题）\n2. 系统太忙啦，像赶集一样拥挤\n3. 网络君又在玩捉迷藏\n4. 服务器去度假了（维护中）\n5. 参数设置得太严格，把AI管得太紧\n6. 小懿币用光了，该给能量补给站充能啦！',
                        ),
                        _buildExpandableFAQ(
                          '小懿币去哪里了？',
                          '',
                          action: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SponsorPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.rocket_launch, size: 16),
                                SizedBox(width: 4),
                                Text('前往小懿能量补给站'),
                              ],
                            ),
                          ),
                        ),
                        _buildExpandableFAQ(
                          '如何备份我的角色数据？',
                          '别担心，你的角色数据都安全地躺在本地存储里呢！\n\n云端备份功能正在马不停蹄地开发中，很快就能让你的角色们在云端安家啦！☁️',
                        ),
                        _buildExpandableFAQ(
                          '为什么聊天会越聊消耗越多？',
                          '聊天消耗越来越多是因为：\n\n1. 上下文积累 - 随着对话进行，AI需要记住之前的内容，消耗会随着对话长度增加\n2. 复杂回复 - 当话题变得深入或复杂，生成更详细的回复需要更多算力\n3. 创意输出 - 如描述场景、编写故事等创意内容比简单问答消耗更多\n\n小技巧：可以适时开启"上下文限制"`，减少消耗！',
                        ),
                        _buildExpandableFAQ(
                          'Token是怎么计算的？',
                          'Token计算小科普：\n\n1. 什么是Token？\n一个token大致相当于4个字符或0.75个汉字，是AI处理语言的基本单位\n\n2. 计算方式：\n• 中文：一个汉字约等于1.3~1.5个token\n• 英文：一个单词约等于1~2个token\n• 标点符号：每个标点通常是1个token\n• 特殊字符：可能需要更多token\n\n3. 消耗计算：\n对话消耗 = 输入token数量 + 输出token数量\n\n所以，相同长度的中文比英文消耗更多哦！',
                        ),
                      ],
                    ),
                  ),

                  // 智能客服入口
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // 跳转到智能客服对话页面
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ServiceAssistantPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.smart_toy,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '智能客服',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '24小时在线，为您解答使用过程中的问题',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFAQ(String question, String answer, {Widget? action}) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  Center(child: action),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
