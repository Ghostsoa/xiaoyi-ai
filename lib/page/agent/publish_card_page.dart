import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import '../../net/agent/agent_card_service.dart';
import '../../components/loading_overlay.dart';
import '../../components/custom_snack_bar.dart';
import '../../page/worldbook/worldbook_list_page.dart';

class PublishCardPage extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? cardDetail;

  const PublishCardPage({
    super.key,
    this.isEdit = false,
    this.cardDetail,
  });

  @override
  State<PublishCardPage> createState() => _PublishCardPageState();
}

class _PublishCardPageState extends State<PublishCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _agentCardService = AgentCardService();

  // 基本信息
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _settingController = TextEditingController();
  final _instructionController = TextEditingController();

  // 模型设置
  String _selectedModel = 'gemini-2.0-flash';
  final _temperatureController = TextEditingController(text: '0.7');
  final _topPController = TextEditingController(text: '0.9');
  final _topKController = TextEditingController(text: '40');
  final _maxTokensController = TextEditingController(text: '2000');

  // 高级设置
  final _customFieldsController = TextEditingController();
  final _userPrefixController = TextEditingController();
  final _userSuffixController = TextEditingController();
  final _customRulesController = TextEditingController();
  final _keywordMatchDepthController = TextEditingController(text: '5');
  bool _enableFunctionCall = false;

  // 状态
  int _status = 1; // 1: 预览版, 2: 正式版
  bool _isSubmitting = false;
  List<int> _worldbookEntryIds = [];

  // 图片
  File? _coverImage;
  File? _backgroundImage;
  String? _coverBase64;
  String? _backgroundBase64;

  // 模型列表
  final List<String> _modelOptions = [
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash-exp'
  ];

  @override
  void initState() {
    super.initState();

    // 如果是编辑模式，初始化表单数据
    if (widget.isEdit && widget.cardDetail != null) {
      final detail = widget.cardDetail!;

      // 基本信息
      _nameController.text = detail['name'] ?? '';
      _descriptionController.text = detail['description'] ?? '';
      _tagsController.text = detail['tags'] ?? '';
      _settingController.text = detail['setting'] ?? '';
      _instructionController.text = detail['instruction'] ?? '';

      // 世界书条目ID
      _worldbookEntryIds = List<int>.from(detail['worldbook_entry_ids'] ?? []);

      // 模型设置
      _selectedModel = detail['model_name'] ?? 'gemini-2.0-flash';
      _temperatureController.text = (detail['temperature'] ?? 0.7).toString();
      _topPController.text = (detail['top_p'] ?? 0.9).toString();
      _topKController.text = (detail['top_k'] ?? 40).toString();
      _maxTokensController.text = (detail['max_tokens'] ?? 2000).toString();

      // 高级设置
      _customFieldsController.text = detail['custom_fields'] != null
          ? json.encode(detail['custom_fields'])
          : '{}';
      _userPrefixController.text = detail['user_prefix'] ?? '';
      _userSuffixController.text = detail['user_suffix'] ?? '';
      _customRulesController.text = detail['custom_rules'] ?? '';
      _keywordMatchDepthController.text =
          (detail['keyword_match_depth'] ?? 5).toString();
      _enableFunctionCall = detail['enable_function_call'] ?? false;

      // 状态
      _status = detail['status'] ?? 1;

      // 图片
      _coverBase64 = detail['cover_base64'];
      _backgroundBase64 = detail['background_base64'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _settingController.dispose();
    _instructionController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    _maxTokensController.dispose();
    _customFieldsController.dispose();
    _userPrefixController.dispose();
    _userSuffixController.dispose();
    _customRulesController.dispose();
    _keywordMatchDepthController.dispose();
    super.dispose();
  }

  Future<void> _selectImage(bool isCover) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // 读取原始图片
      final File originalFile = File(pickedFile.path);
      final img.Image? originalImage =
          img.decodeImage(await originalFile.readAsBytes());

      if (originalImage != null) {
        img.Image processedImage;

        if (isCover) {
          // 封面图片：压缩到 300x300
          processedImage = img.copyResize(originalImage,
              width: 300, height: 300, interpolation: img.Interpolation.linear);
        } else {
          // 背景图片：保持原始尺寸，仅进行质量压缩
          processedImage = originalImage;
        }

        // 创建临时文件保存处理后的图片
        final String tempPath =
            originalFile.path.replaceAll(RegExp(r'\.[^.]*$'), '_processed.jpg');
        final File processedFile = File(tempPath);

        // 将处理后的图片保存为JPEG格式，质量为85%
        await processedFile
            .writeAsBytes(img.encodeJpg(processedImage, quality: 85));

        setState(() {
          if (isCover) {
            _coverImage = processedFile;
          } else {
            _backgroundImage = processedFile;
          }
        });
      }
    }
  }

  bool _validateJsonFormat(String input, String fieldName) {
    // 如果输入为空或只包含空白字符，则视为有效
    if (input.trim().isEmpty) {
      return true;
    }

    try {
      json.decode(input);
      return true;
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: '$fieldName 格式不正确，请确保是有效的JSON格式',
      );
      return false;
    }
  }

  Future<void> _publishCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 验证JSON格式
    if (!_validateJsonFormat(_customFieldsController.text, '自定义字段')) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final (success, message, data) = await LoadingOverlay.show(
        context,
        future: () {
          // 处理自定义字段
          Map<String, dynamic>? customFieldsJson;
          if (_customFieldsController.text.trim().isNotEmpty) {
            customFieldsJson = json.decode(_customFieldsController.text);
          }

          // 解析关键词搜索深度
          final int? keywordMatchDepth =
              int.tryParse(_keywordMatchDepthController.text);

          return widget.isEdit
              ? _agentCardService.updateAgentCard(
                  id: widget.cardDetail!['id'],
                  name: _nameController.text,
                  description: _descriptionController.text,
                  tags: _tagsController.text,
                  setting: _settingController.text,
                  instruction: _instructionController.text,
                  modelName: _selectedModel,
                  temperature: _temperatureController.text,
                  topP: _topPController.text,
                  topK: _topKController.text,
                  maxTokens: _maxTokensController.text,
                  customFields: customFieldsJson,
                  worldbookEntryIds: _worldbookEntryIds,
                  status: _status,
                  coverImage: _coverImage,
                  backgroundImage: _backgroundImage,
                  userPrefix: _userPrefixController.text,
                  userSuffix: _userSuffixController.text,
                  customRules: _customRulesController.text,
                  enableFunctionCall: _enableFunctionCall,
                  keywordMatchDepth: keywordMatchDepth,
                )
              : _agentCardService.createAgentCard(
                  name: _nameController.text,
                  description: _descriptionController.text,
                  tags: _tagsController.text,
                  setting: _settingController.text,
                  instruction: _instructionController.text,
                  modelName: _selectedModel,
                  temperature: _temperatureController.text,
                  topP: _topPController.text,
                  topK: _topKController.text,
                  maxTokens: _maxTokensController.text,
                  customFields: customFieldsJson,
                  worldbookEntryIds: _worldbookEntryIds,
                  status: _status,
                  coverImage: _coverImage,
                  backgroundImage: _backgroundImage,
                  userPrefix: _userPrefixController.text,
                  userSuffix: _userSuffixController.text,
                  customRules: _customRulesController.text,
                  enableFunctionCall: _enableFunctionCall,
                  keywordMatchDepth: keywordMatchDepth,
                );
        },
        text: widget.isEdit ? '更新中...' : '发布中...',
      );

      if (mounted) {
        if (success) {
          // 显示成功消息
          CustomSnackBar.show(
            context,
            message: message,
          );

          // 使用Future.microtask确保在下一个帧返回，避免动画相关问题
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        } else {
          // 显示错误消息
          CustomSnackBar.show(
            context,
            message: message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: '${widget.isEdit ? "更新" : "发布"}失败: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
          title: Text(
            widget.isEdit ? '编辑大世界' : '发布大世界',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : _publishCard,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isEdit ? '保存' : '发布',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    indicatorColor: Colors.white,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.zero,
                    tabs: const [
                      Tab(text: '封面设置'),
                      Tab(text: '卡设定'),
                      Tab(text: '模型设置'),
                      Tab(text: '高级设置'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 封面设置标签页
                        _buildCoverSettingsTab(),

                        // 角色设定标签页
                        _buildCharacterSettingTab(),

                        // 模型设置标签页
                        _buildModelSettingsTab(),

                        // 高级设置标签页
                        _buildAdvancedSettingsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 新增的封面设置标签页
  Widget _buildCoverSettingsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        // 封面图片和背景图片并排显示
        Row(
          children: [
            // 封面图片选择
            Expanded(
              child: _buildImageSelector(
                title: '封面图片',
                image: _coverImage,
                onTap: () => _selectImage(true),
                description: '800x600',
                base64Image: _coverBase64,
              ),
            ),

            const SizedBox(width: 12),

            // 背景图片选择
            Expanded(
              child: _buildImageSelector(
                title: '背景图片',
                image: _backgroundImage,
                onTap: () => _selectImage(false),
                description: '1920x1080',
                base64Image: _backgroundBase64,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 标签输入
        _buildTextField(
          controller: _tagsController,
          labelText: '标签',
          hintText: '多个标签用逗号分隔，如：聊天,助手,学习',
        ),

        const SizedBox(height: 16),

        // 名称输入
        _buildTextField(
          controller: _nameController,
          labelText: '名称',
          hintText: '请输入大世界名称',
          maxLength: 50,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入名称';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // 简介输入
        _buildTextField(
          controller: _descriptionController,
          labelText: '简介',
          hintText: '请简要描述这个卡吧',
          maxLength: 255,
          minLines: 3,
          maxLines: null, // 设置为null以允许自动扩展
        ),

        const SizedBox(height: 16),

        // 说明输入
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '说明',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: TextFormField(
                controller: _instructionController,
                minLines: 3,
                maxLines: null,
                maxLength: 3000,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '请输入大世界的使用说明...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 提示信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.purple.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.purple.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '精美的封面和简介能让您的大世界吸引更多用户',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 新增的角色设定标签页
  Widget _buildCharacterSettingTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        // 设定输入
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '卡设定',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: TextFormField(
                controller: _settingController,
                minLines: 10,
                maxLines: null, // 设置为null以允许自动扩展
                maxLength: 100000,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '请输入大世界的设定...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入设定';
                  }
                  if (value.length < 20) {
                    return '设定内容至少需要20个字符';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelSettingsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        // 模型选择
        _buildModelDropdown(),

        const SizedBox(height: 24),

        // 温度设置
        _buildSliderField(
          controller: _temperatureController,
          labelText: '温度 (Temperature)',
          hintText: '控制输出的随机性',
          minValue: 0.0,
          maxValue: 2.0,
          defaultValue: 0.7,
        ),

        const SizedBox(height: 24),

        // Top P设置
        _buildSliderField(
          controller: _topPController,
          labelText: '核采样阈值 (Top P)',
          hintText: '控制输出的多样性',
          minValue: 0.0,
          maxValue: 1.0,
          defaultValue: 0.9,
        ),

        const SizedBox(height: 24),

        // Top K设置
        _buildTextField(
          controller: _topKController,
          labelText: '采样词数 (Top K)',
          hintText: '从前K个词中采样',
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 24),

        // 最大Token数
        _buildTextField(
          controller: _maxTokensController,
          labelText: '最大输出Token数',
          hintText: '一次对话最大输出的token数',
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdvancedSettingsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        // 用户前缀
        _buildTextField(
          controller: _userPrefixController,
          labelText: '用户前缀',
          hintText: '可选，在用户消息前添加的文本',
        ),

        const SizedBox(height: 24),

        // 用户后缀
        _buildTextField(
          controller: _userSuffixController,
          labelText: '用户后缀',
          hintText: '可选，在用户消息后添加的文本',
        ),

        const SizedBox(height: 24),

        // 关键词搜索深度
        _buildTextField(
          controller: _keywordMatchDepthController,
          labelText: '关键词搜索深度',
          hintText: '设置从知识库中搜索的最大条目数，默认为5',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入关键词搜索深度';
            }
            final number = int.tryParse(value);
            if (number == null || number < 1) {
              return '请输入大于0的整数';
            }
            return null;
          },
        ),

        const SizedBox(height: 24),

        // 自定义规则
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自定义规则',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: TextFormField(
                controller: _customRulesController,
                minLines: 4,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '请输入自定义规则...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 启用函数调用
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '启用函数调用(暂时没用)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '允许调用系统函数',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enableFunctionCall,
                onChanged: (value) {
                  setState(() {
                    _enableFunctionCall = value;
                  });
                },
                activeColor: Colors.greenAccent,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 自定义字段
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自定义字段 (JSON格式)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: TextFormField(
                controller: _customFieldsController,
                minLines: 4,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      '例如：\n{\n  "字段1": "值1",\n  "字段2": 123,\n  "字段3": true\n}',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 选择世界书启用条目按钮
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '世界书条目',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (_worldbookEntryIds.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '已选择 ${_worldbookEntryIds.length} 项',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final result = await Navigator.push<List<int>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorldbookListPage(
                      selectedIds: _worldbookEntryIds,
                    ),
                  ),
                );

                if (result != null && mounted) {
                  setState(() {
                    _worldbookEntryIds = result;
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          color: Colors.amber.withOpacity(0.8),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '选择世界书条目',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 状态选择
        _buildStatusSelector(),

        const SizedBox(height: 30),

        // 提示信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '发布提示',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. 预览版用户仅可查看简介和说明，无法创建会话\n'
                '2. 正式版发布后所有用户可用，确保您的内容符合社区规范\n'
                '3. JSON格式必须正确，否则将无法保存',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        errorStyle: TextStyle(color: Colors.red.shade300),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        counterStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
      validator: validator,
    );
  }

  Widget _buildSliderField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required double minValue,
    required double maxValue,
    required double defaultValue,
  }) {
    // 解析控制器的值为double，如果解析失败则使用默认值
    double value = double.tryParse(controller.text) ?? defaultValue;
    if (value < minValue) value = minValue;
    if (value > maxValue) value = maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$labelText: ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hintText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              minValue.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: minValue,
                max: maxValue,
                divisions: ((maxValue - minValue) * 10).toInt(),
                activeColor: Colors.greenAccent,
                inactiveColor: Colors.white.withOpacity(0.3),
                onChanged: (newValue) {
                  setState(() {
                    controller.text = newValue.toStringAsFixed(2);
                  });
                },
              ),
            ),
            Text(
              maxValue.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '模型选择',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
            ),
            icon: Icon(Icons.arrow_drop_down,
                color: Colors.white.withOpacity(0.7)),
            dropdownColor: Theme.of(context).primaryColor.withOpacity(0.9),
            style: const TextStyle(color: Colors.white),
            items: _modelOptions.map((model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(model),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedModel = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required String description,
    String? base64Image,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: image != null || base64Image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image != null)
                      Image.file(
                        image,
                        fit: BoxFit.cover,
                      )
                    else if (base64Image != null)
                      _buildBase64Image(base64Image),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (title == '封面图片') {
                                _coverImage = null;
                                _coverBase64 = null;
                              } else {
                                _backgroundImage = null;
                                _backgroundBase64 = null;
                              }
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '点击选择',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBase64Image(String base64String) {
    try {
      final startIndex = base64String.indexOf(',');
      final imageData = startIndex != -1
          ? base64String.substring(startIndex + 1)
          : base64String;
      return Image.memory(
        base64Decode(imageData),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.error_outline,
            size: 36,
            color: Colors.white.withOpacity(0.7),
          );
        },
      );
    } catch (e) {
      return Icon(
        Icons.error_outline,
        size: 36,
        color: Colors.white.withOpacity(0.7),
      );
    }
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '发布状态',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusOption(
                  title: '预览版',
                  description: '仅自己可见，可修改',
                  value: 1,
                  icon: Icons.visibility_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusOption(
                  title: '正式版',
                  description: '所有人可见',
                  value: 2,
                  icon: Icons.public,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String description,
    required int value,
    required IconData icon,
  }) {
    final bool isSelected = _status == value;

    return InkWell(
      onTap: () {
        setState(() {
          _status = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.greenAccent
                  : Colors.white.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
