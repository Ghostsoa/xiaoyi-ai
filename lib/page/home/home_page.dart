import 'dart:ui';
import 'package:flutter/material.dart';
import '../message/message_page.dart';
import '../plaza/plaza_page.dart';
import '../profile/profile_page.dart';
import '../../net/profile/profile_service.dart';
import '../../net/http_client.dart';
import '../../service/character_card_service.dart';
import '../../service/chat_history_service.dart';
import '../../service/chat_list_service.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final CharacterCardService characterCardService;
  final ChatHistoryService chatHistoryService;
  final ChatListService chatListService;

  const HomePage({
    super.key,
    required this.characterCardService,
    required this.chatHistoryService,
    required this.chatListService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _profileService = ProfileService();
  Map<String, dynamic>? _assetData;
  DateTime? _lastFetchTime;
  final _messagePageKey = GlobalKey<MessagePageState>();

  final List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: const Icon(Icons.chat_bubble_outline),
      selectedIcon: const Icon(Icons.chat_bubble),
      label: '消息',
    ),
    NavigationDestination(
      icon: const Icon(Icons.dashboard_outlined),
      selectedIcon: const Icon(Icons.dashboard),
      label: '大厅',
    ),
    NavigationDestination(
      icon: const Icon(Icons.person_outline),
      selectedIcon: const Icon(Icons.person),
      label: '我的',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 设置 HttpClient 的全局 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HttpClient.setContext(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台回到前台，执行刷新操作
      if (_currentIndex == 0) {
        _messagePageKey.currentState?.checkNotificationStatus();
        _messagePageKey.currentState?.refreshMessages();
        _messagePageKey.currentState?.checkVersion();
      } else if (_currentIndex == 2) {
        _loadAssetInfo();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在应用从后台回到前台或首次加载时检查
    if (_currentIndex == 0) {
      _messagePageKey.currentState?.checkNotificationStatus();
      _messagePageKey.currentState?.refreshMessages();
      _messagePageKey.currentState?.checkVersion();
    } else if (_currentIndex == 2) {
      _loadAssetInfo();
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    // 当切换到消息页面时刷新
    if (index == 0) {
      _messagePageKey.currentState?.refreshMessages();
      _messagePageKey.currentState?.checkNotificationStatus();
      _messagePageKey.currentState?.checkVersion();
    }
    // 当切换到个人页面时加载资产信息
    if (index == 2) {
      _loadAssetInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 页面内容使用 IndexedStack 保持页面状态
          IndexedStack(
            index: _currentIndex,
            children: [
              MessagePage(
                key: _messagePageKey,
                chatListService: widget.chatListService,
                characterCardService: widget.characterCardService,
                chatHistoryService: widget.chatHistoryService,
              ),
              PlazaPage(
                characterCardService: widget.characterCardService,
                chatHistoryService: widget.chatHistoryService,
                chatListService: widget.chatListService,
              ),
              ProfilePage(assetData: _assetData),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      );
                    }
                    return TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    );
                  }),
                ),
              ),
              child: NavigationBar(
                height: 65,
                selectedIndex: _currentIndex,
                onDestinationSelected: _onDestinationSelected,
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                animationDuration: const Duration(milliseconds: 400),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: _destinations.map((destination) {
                  return NavigationDestination(
                    icon: _buildIcon(
                      destination.icon,
                      isSelected: false,
                    ),
                    selectedIcon: _buildIcon(
                      destination.selectedIcon,
                      isSelected: true,
                    ),
                    label: destination.label,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadAssetInfo() async {
    try {
      // 如果距离上次请求不足5秒，则使用缓存数据
      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) <
              const Duration(seconds: 5)) {
        print('使用缓存的资产信息');
        return;
      }

      final (assetInfo, message) = await _profileService.getAssetInfo();
      if (assetInfo != null && mounted) {
        // 比较数据是否有变化
        if (_assetData != null &&
            _assetData!['balance'] == assetInfo['balance'] &&
            _assetData!['level'] == assetInfo['level'] &&
            _assetData!['exp'] == assetInfo['exp'] &&
            _assetData!['exp_progress'] == assetInfo['exp_progress'] &&
            _assetData!['next_level_exp'] == assetInfo['next_level_exp'] &&
            _assetData!['remaining_hours'] == assetInfo['remaining_hours']) {
          print('资产信息未发生变化');
          return;
        }

        setState(() {
          _assetData = assetInfo;
          _lastFetchTime = DateTime.now();
        });
        print('资产信息已更新');
      } else if (mounted && message != null) {
        print('加载资产信息失败: $message');
      }
    } catch (e) {
      print('加载资产信息失败: $e');
    }
  }

  Widget _buildIcon(Widget? icon, {required bool isSelected}) {
    return IconTheme(
      data: IconThemeData(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
        size: 24,
      ),
      child: icon ?? const Icon(Icons.circle_outlined),
    );
  }
}
