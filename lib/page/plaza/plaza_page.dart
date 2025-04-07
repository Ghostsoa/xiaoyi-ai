import 'package:flutter/material.dart';
import '../../service/character_card_service.dart';
import '../../service/chat_history_service.dart';
import 'local_plaza_page.dart';
import 'online_plaza_page.dart';
import 'character_edit_page.dart';
import '../../service/chat_list_service.dart';
import 'creation_plaza_page.dart';

class PlazaPage extends StatefulWidget {
  final CharacterCardService characterCardService;
  final ChatHistoryService chatHistoryService;
  final ChatListService chatListService;
  const PlazaPage({
    super.key,
    required this.characterCardService,
    required this.chatHistoryService,
    required this.chatListService,
  });

  @override
  State<PlazaPage> createState() => _PlazaPageState();
}

class _PlazaPageState extends State<PlazaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _localPlazaKey = GlobalKey<LocalPlazaPageState>();
  final _creationPlazaKey = GlobalKey<CreationPlazaPageState>();

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
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '本地'),
              Tab(text: '在线'),
              Tab(text: '创作'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                if (_tabController.index == 0) {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CharacterEditPage(
                        characterCardService: widget.characterCardService,
                      ),
                    ),
                  );
                  if (result == true) {
                    _localPlazaKey.currentState?.refreshCards();
                  }
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: TabBarView(
              controller: _tabController,
              children: [
                LocalPlazaPage(
                  key: _localPlazaKey,
                  characterCardService: widget.characterCardService,
                  chatHistoryService: widget.chatHistoryService,
                  chatListService: widget.chatListService,
                ),
                const OnlinePlazaPage(),
                CreationPlazaPage(
                  key: _creationPlazaKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
