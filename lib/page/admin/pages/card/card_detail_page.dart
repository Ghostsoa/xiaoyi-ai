import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../net/admin/card_service.dart';
import '../../../../components/custom_snack_bar.dart';

class CardDetailPage extends StatefulWidget {
  final String batchNo;

  const CardDetailPage({super.key, required this.batchNo});

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _cards = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalItems = 0;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();

  // 添加搜索参数
  final TextEditingController _cardNoController = TextEditingController();
  String? _selectedUsedStatus;

  @override
  void initState() {
    super.initState();
    _loadCards();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _cardNoController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _loadMoreCards();
      }
    }
  }

  Future<void> _loadCards() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      // 构建查询参数
      dynamic usedParam;
      if (_selectedUsedStatus == '已使用') {
        usedParam = true;
      } else if (_selectedUsedStatus == '未使用') {
        usedParam = false;
      }

      final result = await CardService.getCardList(
        batchNo: widget.batchNo,
        cardNo: _cardNoController.text.trim().isNotEmpty
            ? _cardNoController.text.trim()
            : null,
        used: usedParam,
        page: _currentPage,
        pageSize: _pageSize,
      );
      setState(() {
        _cards = List<Map<String, dynamic>>.from(result['items']);
        _totalItems = result['total'] ?? 0;
        _totalPages = (_totalItems / _pageSize).ceil();
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载卡密列表失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreCards() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;

      // 构建查询参数
      dynamic usedParam;
      if (_selectedUsedStatus == '已使用') {
        usedParam = true;
      } else if (_selectedUsedStatus == '未使用') {
        usedParam = false;
      }

      final result = await CardService.getCardList(
        batchNo: widget.batchNo,
        cardNo: _cardNoController.text.trim().isNotEmpty
            ? _cardNoController.text.trim()
            : null,
        used: usedParam,
        page: nextPage,
        pageSize: _pageSize,
      );

      final newCards = List<Map<String, dynamic>>.from(result['items']);

      setState(() {
        _cards.addAll(newCards);
        _currentPage = nextPage;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载更多卡密失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // 复制单个卡密
  Future<void> _copyCardInfo(Map<String, dynamic> card) async {
    final String cardNo = card['card_no'] ?? '';

    await Clipboard.setData(ClipboardData(text: cardNo));
    if (mounted) {
      CustomSnackBar.show(context, message: '已复制卡号');
    }
  }

  // 复制所有未使用的卡密
  Future<void> _copyAllCards() async {
    if (_cards.isEmpty) {
      CustomSnackBar.show(context, message: '没有可复制的卡密');
      return;
    }

    // 筛选未使用的卡密
    final unusedCards = _cards.where((card) => card['used'] != true).toList();

    if (unusedCards.isEmpty) {
      CustomSnackBar.show(context, message: '没有未使用的卡密可复制');
      return;
    }

    final StringBuffer buffer = StringBuffer();

    for (final card in unusedCards) {
      buffer.writeln(card['card_no']);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      CustomSnackBar.show(context, message: '已复制${unusedCards.length}个未使用的卡号');
    }
  }

  void _search() {
    _loadCards();
  }

  void _resetSearch() {
    setState(() {
      _cardNoController.clear();
      _selectedUsedStatus = null;
    });
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '批次 ${widget.batchNo}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isLoading)
              Text(
                '共 $_totalItems 条记录',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all, color: Colors.white),
            onPressed: _isLoading ? null : _copyAllCards,
            tooltip: '复制未使用的卡号',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadCards,
            tooltip: '刷新',
          ),
        ],
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_cards.isEmpty) {
      return const Center(
        child: Text(
          '暂无卡密数据',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return SafeArea(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.white24,
          dataTableTheme: DataTableTheme.of(context).copyWith(
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            dataTextStyle: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        child: Column(
          children: [
            // 搜索区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardNoController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        hintText: '输入卡号搜索',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        prefixIcon:
                            Icon(Icons.search, size: 18, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black12,
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String?>(
                      value: _selectedUsedStatus,
                      hint: const Text('使用状态',
                          style: TextStyle(color: Colors.white70)),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white70),
                      dropdownColor: Colors.black87,
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('全部状态',
                              style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: '已使用',
                          child: Text('已使用',
                              style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: '未使用',
                          child: Text('未使用',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUsedStatus = value;
                        });
                        _search();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _resetSearch,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: '重置筛选',
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowHeight: 56,
                    dividerThickness: 0.5,
                    columns: const [
                      DataColumn(label: Text('卡号')),
                      DataColumn(label: Text('类型')),
                      DataColumn(label: Text('状态')),
                      DataColumn(label: Text('使用者ID')),
                      DataColumn(label: Text('详情')),
                      DataColumn(label: Text('操作')),
                    ],
                    rows: _cards.map((card) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              card['card_no'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              card['card_type'] == 1 ? '金额卡' : '时长卡',
                              style: TextStyle(
                                color: card['card_type'] == 1
                                    ? Colors.lightBlueAccent
                                    : Colors.lightGreenAccent,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              card['used'] == true ? '已使用' : '未使用',
                              style: TextStyle(
                                color: card['used'] == true
                                    ? Colors.white70
                                    : Colors.greenAccent,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              card['used'] == true
                                  ? '${card['user_id'] ?? '未知'}'
                                  : '-',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          DataCell(
                            Text(
                              card['card_type'] == 1
                                  ? '${card['amount']}小懿币'
                                  : '${card['duration']}小时',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.copy_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => _copyCardInfo(card),
                              tooltip: '复制卡号',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_cardNoController.text.isNotEmpty ||
                      _selectedUsedStatus != null)
                    Text(
                      '搜索结果: ${_selectedUsedStatus ?? ''} ${_cardNoController.text.isNotEmpty ? '卡号包含 "${_cardNoController.text}"' : ''}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    )
                  else
                    const SizedBox(),
                  Text(
                    '已加载 ${_cards.length}/$_totalItems 条',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
