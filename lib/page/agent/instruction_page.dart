import 'package:flutter/material.dart';

class InstructionPage extends StatefulWidget {
  const InstructionPage({super.key});

  @override
  State<InstructionPage> createState() => _InstructionPageState();
}

class _InstructionPageState extends State<InstructionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创作中心说明'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '使用声明'),
            Tab(text: '创作指南'),
            Tab(text: '高级功能'),
          ],
        ),
      ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDeclarationTab(),
            _buildGuideTab(),
            _buildAdvancedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeclarationTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection(
          title: '使用声明',
          children: [
            _buildParagraph('为维护健康、积极的社区环境，所有创作者必须遵守以下规定：'),
            _buildPoint('内容合规', '不得发布任何含有暴力、色情、歧视、辱骂国家或民族、违反法律法规的内容。'),
            _buildPoint('原创尊重', '创作内容应当尊重原创，避免抄袭、剽窃他人作品，引用他人内容应当注明来源。'),
            _buildPoint('诚信原则', '不得发布虚假、误导性信息或进行欺诈行为。'),
            _buildRedAlert('违反上述规定的账户可能被限制使用创作功能或永久禁止访问平台。'),
          ],
        ),
        _buildSection(
          title: '免责声明',
          children: [
            _buildParagraph('本平台仅为用户提供大世界创作和使用的技术服务，不对用户创作的内容负责。'),
            _buildParagraph('用户应当自行对其创作内容负责，并承担由此产生的一切法律责任。'),
            _buildParagraph('本平台保留对违规内容进行删除和对违规用户进行处罚的权利。'),
          ],
        ),
        _buildSection(
          title: '版权声明',
          children: [
            _buildParagraph('用户在本平台创作的大世界卡片归用户所有，但用户授权本平台在服务范围内使用该内容。'),
            _buildParagraph('本平台提供的模板、素材等资源的知识产权归本平台所有，用户仅有使用权。'),
          ],
        ),
      ],
    );
  }

  Widget _buildGuideTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection(
          title: '创作须知',
          children: [
            _buildParagraph('在开始创作之前，请先阅读以下重要说明，以确保您的创作顺利进行，并符合平台规范。'),
            _buildParagraph('创作中心仍处于测试阶段，部分功能可能不稳定，我们会持续优化和改进。'),
          ],
        ),
        _buildSection(
          title: '智能卡发布指南',
          children: [
            _buildPoint('名称设置', '取一个简洁明了、能够体现卡片特性的名称，避免过长或过于模糊的表述。'),
            _buildPoint('描述撰写', '详细描述卡片的功能、用途和特色，让用户能够清楚地了解该卡片的价值。'),
            _buildPoint('标签选择', '添加3-5个相关标签，帮助用户更容易找到您的卡片。标签之间用逗号分隔。'),
            _buildPoint('设定与指令', '这是卡片的核心部分，详细定义大世界的行为模式和响应策略。'),
            _buildPoint('模型选择', '根据卡片功能选择合适的模型，不同模型有不同的能力和特点。'),
            _buildPoint('图片上传', '上传清晰、美观且与卡片主题相关的封面和背景图片，增强用户体验。'),
          ],
        ),
        _buildSection(
          title: '世界书编辑说明',
          children: [
            _buildParagraph('世界书是智能卡的知识库，您可以在这里添加专业知识、背景设定或角色信息等内容。'),
            _buildPoint('创建条目', '每个条目应该聚焦于一个明确的主题或概念，内容精炼且有针对性。'),
            _buildPoint('关联智能卡', '您可以将世界书条目关联到特定的智能卡，使其具备相应的知识背景。'),
            _buildParagraph('世界书的质量直接影响智能卡的表现，建议投入足够的时间完善内容。'),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSection(
          title: '1. 世界书系统',
          children: [
            _buildSubsection('1.1 关键词匹配'),
            _buildBulletPoint('支持设置关键词匹配深度（KeywordMatchDepth）'),
            _buildBulletPoint('默认匹配最近5轮对话'),
            _buildBulletPoint('按优先级（Priority）自动排序并去重'),
            _buildBulletPoint('支持用户消息和AI回复的双向关键词匹配'),
            _buildSubsection('1.2 强制引用语法'),
            _buildParagraph('使用 `<wb.关键词>` 语法可以在规则中强制引用世界书条目，例如：'),
            _buildCodeBlock('''<wb.人物背景>
<wb.性格特点>'''),
          ],
        ),
        _buildSection(
          title: '2. 自定义规则系统',
          children: [
            _buildSubsection('2.1 规则语法'),
            _buildParagraph('自定义规则支持以下语法：'),
            _buildSubPoint('条件判断'),
            _buildCodeBlock('''{{f.字段名<值}}<f.字段名=值>{{/if}}'''),
            _buildParagraph('支持的操作符：>, <, ==, !=, >=, <='),
            _buildSubPoint('字段操作'),
            _buildCodeBlock('''<f.字段名=值>  // 设置字段值
<f.字段名=random(最小值,最大值)>  // 设置随机数值'''),
            _buildSubPoint('世界书引用'),
            _buildCodeBlock('''<wb.关键词>  // 强制引用世界书条目'''),
            _buildSubsection('2.2 规则使用说明'),
            _buildBulletPoint('多个规则之间用逗号分隔'),
            _buildBulletPoint('最多支持5个规则同时生效'),
            _buildBulletPoint('规则执行顺序按照定义顺序'),
            _buildSubsection('2.3 规则示例'),
            _buildCodeBlock('''// 示例1：设置心情值并根据生命值状态恢复生命
<f.心情=80>,{{f.生命<50}}<f.生命=random(90,100)>{{/if}}

// 示例2：根据条件引用不同世界书条目
{{f.心情>80}}<wb.开心>{{else}}<wb.平静>{{/if}}

// 示例3：根据条件修改状态
{{f.体力<20}}<f.状态=疲惫><wb.疲惫>{{/if}}

// 示例4：设置随机心情值并引用相应状态
<f.心情=random(1,100)>,{{f.心情>=80}}<wb.非常开心>{{else}}<wb.一般心情>{{/if}}

// 示例5：字段值的增减操作
<f.金币+=10>,<f.体力-=5>'''),
          ],
        ),
        _buildSection(
          title: '3. 会话状态管理',
          children: [
            _buildSubsection('3.1 自定义字段'),
            _buildBulletPoint('严格按照JSON格式的键值对'),
            _buildBulletPoint('字段值在对话中实时更新'),
            _buildBulletPoint('所有字段变更会同步保存到数据库和缓存'),
            _buildSubsection('3.2 设定模板语法'),
            _buildParagraph('设定中支持以下三种基础模板语法：'),
            _buildSubPoint('用户输入'),
            _buildCodeBlock('''{{用户}}  // 需要用户输入的字段'''),
            _buildSubPoint('选择类型'),
            _buildCodeBlock('''{{选项1/选项2/选项3}}  // 用户从多个选项中选择一个'''),
            _buildSubPoint('随机类型'),
            _buildCodeBlock('''{{选项1|选项2|选项3}}  // 系统随机选择一个选项'''),
            _buildParagraph('示例：'),
            _buildCodeBlock('''姓名：{{用户}}
性别：{{男/女}}
性格：{{开朗|温和|活泼}}'''),
            _buildParagraph('当存在用户输入语法和选择语法时，系统会引导用户在创建会话时输入相关内容。创作者可以自由替换内容。'),
          ],
        ),
        _buildSection(
          title: '4. 对话控制',
          children: [
            _buildSubsection('4.1 前缀后缀'),
            _buildBulletPoint('支持为用户输入添加固定前缀（UserPrefix）'),
            _buildBulletPoint('支持为用户输入添加固定后缀（UserSuffix）'),
            _buildBulletPoint('前缀后缀在发送到模型前自动添加，注意，我们不会做任何修饰，请自行添加'),
            _buildSubsection('4.2 模型参数'),
            _buildBulletPoint('Temperature：控制回复的随机性'),
            _buildBulletPoint('TopP：控制核采样概率'),
            _buildBulletPoint('TopK：控制词汇选择范围'),
            _buildBulletPoint('MaxTokens：控制最大输出长度'),
          ],
        ),
        _buildSection(
          title: '5. 最佳实践',
          children: [
            _buildSubsection('5.1 世界书编写建议'),
            _buildBulletPoint('按优先级组织内容'),
            _buildBulletPoint('关键词尽量具体'),
            _buildBulletPoint('相关内容可使用相同优先级'),
            _buildBulletPoint('条目最好不要超过3000字'),
            _buildSubsection('5.2 性能优化建议'),
            _buildBulletPoint('合理设置关键词匹配深度'),
            _buildBulletPoint('及时清理不需要的世界书条目'),
            _buildBulletPoint('自定义规则不要超过5个'),
            _buildSubsection('5.3 字段管理建议'),
            _buildBulletPoint('使用有意义的字段名称'),
            _buildBulletPoint('数值型字段初始化时设置合理范围'),
            _buildBulletPoint('在规则中适当使用随机值增加互动性'),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubsection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPoint(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16),
      child: Text(
        '- $text',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 16, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildRedAlert(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
