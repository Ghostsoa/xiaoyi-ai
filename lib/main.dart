import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page/login/login_page.dart';
import 'page/login/register_page.dart';
import 'page/home/home_page.dart';
import 'page/profile/sponsor_page.dart';
import 'page/profile/invite_page.dart';
import 'dao/storage_dao.dart';
import 'dao/character_card_dao.dart';
import 'service/character_card_service.dart';
import 'dao/chat_history_dao.dart';
import 'service/chat_history_service.dart';
import 'dao/chat_list_dao.dart';
import 'service/chat_list_service.dart';
import 'page/notification/notification_page.dart';
import 'service/secure_storage.dart';
import 'page/login/forgot_password_page.dart';
import 'page/lottery/lottery_page.dart';
//import 'page/notification/notification_detail_page.dart';

Future<void> _requestPermissions() async {
  // 请求照片权限
  await Permission.photos.request();
  // 请求相机权限
  await Permission.camera.request();
  // 请求存储权限
  await Permission.storage.request();
  // 请求媒体库权限
  await Permission.mediaLibrary.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final characterCardDao = CharacterCardDao(prefs);
  final chatHistoryDao = ChatHistoryDao(prefs);
  final chatListDao = ChatListDao(prefs);
  // TODO: 从用户系统获取实际的用户ID
  final characterCardService =
      CharacterCardService(characterCardDao, "test_user");
  final chatHistoryService = ChatHistoryService(chatHistoryDao);
  final chatListService = ChatListService(chatListDao);

  // 请求必要的权限
  await _requestPermissions();

  // 强制竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 使用 edgeToEdge 模式
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // 设置状态栏和导航栏样式为完全透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  // 优化渲染性能
  RenderObject.debugCheckingIntrinsics = false;
  debugPrintMarkNeedsLayoutStacks = false;
  debugPrintMarkNeedsPaintStacks = false;

  // 设置图像缓存限制
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  final storageDao = StorageDao();
  await storageDao.init(); // 初始化 StorageDao
  final themeColors = await storageDao.getThemeColors();

  // 初始化安全存储服务
  final secureStorage = SecureStorage();
  await secureStorage.initializeDefaultKeys();

  runApp(MyApp(
    initialPrimaryColor: themeColors.$1,
    initialSecondaryColor: themeColors.$2,
    characterCardService: characterCardService,
    chatHistoryService: chatHistoryService,
    chatListService: chatListService,
  ));
}

class MyApp extends StatefulWidget {
  final Color initialPrimaryColor;
  final Color initialSecondaryColor;
  final CharacterCardService characterCardService;
  final ChatHistoryService chatHistoryService;
  final ChatListService chatListService;

  const MyApp({
    super.key,
    required this.initialPrimaryColor,
    required this.initialSecondaryColor,
    required this.characterCardService,
    required this.chatHistoryService,
    required this.chatListService,
  });

  static _MyAppState of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>()!;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Color _primaryColor;
  late Color _secondaryColor;
  late CharacterCardService _characterCardService;
  late ChatHistoryService _chatHistoryService;
  late ChatListService _chatListService;

  @override
  void initState() {
    super.initState();
    _primaryColor = widget.initialPrimaryColor;
    _secondaryColor = widget.initialSecondaryColor;
    _characterCardService = widget.characterCardService;
    _chatHistoryService = widget.chatHistoryService;
    _chatListService = widget.chatListService;
  }

  void updateThemeColors(Color primary, Color secondary) {
    setState(() {
      _primaryColor = primary;
      _secondaryColor = secondary;
    });
    StorageDao().saveThemeColors(primary, secondary);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小懿AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          secondary: _secondaryColor,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => HomePage(
              characterCardService: _characterCardService,
              chatHistoryService: _chatHistoryService,
              chatListService: _chatListService,
            ),
        '/sponsor': (context) => const SponsorPage(),
        '/notifications': (context) => const NotificationPage(),
        '/lottery': (context) => const LotteryPage(),
        '/invite': (context) => const InvitePage(),
      },
    );
  }
}
