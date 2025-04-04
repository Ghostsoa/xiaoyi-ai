import 'package:flutter/material.dart';
import '../../../../net/admin/card_service.dart';
import '../../../../components/custom_snack_bar.dart';
import 'card_detail_page.dart';

class CardManagePage extends StatefulWidget {
  const CardManagePage({super.key});

  @override
  State<CardManagePage> createState() => _CardManagePageState();
}

class _CardManagePageState extends State<CardManagePage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _batches = [];
  final int _currentPage = 1;
  final int _pageSize = 10;
  final List<String> _selectedBatchNos = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CardService.getCardBatches(
        page: _currentPage,
        pageSize: _pageSize,
      );
      setState(() {
        _batches = List<Map<String, dynamic>>.from(result['items']);
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: '加载卡密批次失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateCards() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const GenerateCardDialog(),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await CardService.generateCards(
          cardType: result['cardType'],
          amount: result['amount'],
          duration: result['duration'],
          count: result['count'],
        );
        if (mounted) {
          CustomSnackBar.show(context, message: '生成卡密成功');
          _loadBatches();
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(context, message: '生成卡密失败：$e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _deleteBatches() async {
    if (_selectedBatchNos.isEmpty) {
      CustomSnackBar.show(context, message: '请选择要删除的批次');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedBatchNos.length} 个批次吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await CardService.deleteCardBatches(_selectedBatchNos);
        if (mounted) {
          CustomSnackBar.show(context, message: '删除批次成功');
          setState(() {
            _selectedBatchNos.clear();
          });
          _loadBatches();
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(context, message: '删除批次失败：$e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _viewBatchDetails(String batchNo) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardDetailPage(batchNo: batchNo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, size: 24),
              const SizedBox(width: 8),
              const Text(
                '卡密管理',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _isLoading ? null : _generateCards,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  '生成卡密',
                  style: TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isLoading || _selectedBatchNos.isEmpty
                    ? null
                    : _deleteBatches,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(
                  _selectedBatchNos.isEmpty
                      ? '删除'
                      : '${_selectedBatchNos.length}',
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _batches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '暂无卡密批次',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _generateCards,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('生成卡密'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _batches.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final batch = _batches[index];
                        final isSelected =
                            _selectedBatchNos.contains(batch['batch_no']);

                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          tileColor:
                              Theme.of(context).primaryColor.withOpacity(0.02),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedBatchNos.add(batch['batch_no']);
                                } else {
                                  _selectedBatchNos.remove(batch['batch_no']);
                                }
                              });
                            },
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '批次号：${batch['batch_no']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: batch['card_type'] == 1
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  batch['card_type'] == 1 ? '余额卡' : '无限对话卡',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: batch['card_type'] == 1
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          batch['card_type'] == 1
                                              ? '小懿币${batch['amount']}'
                                              : '时长：${batch['duration']}小时',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          '数量：${batch['count']}',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () =>
                                _viewBatchDetails(batch['batch_no']),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text(
                              '详情',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class GenerateCardDialog extends StatefulWidget {
  const GenerateCardDialog({super.key});

  @override
  State<GenerateCardDialog> createState() => _GenerateCardDialogState();
}

class _GenerateCardDialogState extends State<GenerateCardDialog> {
  int _cardType = 1;
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _countController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('生成卡密'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 1,
                label: Text('余额卡'),
              ),
              ButtonSegment(
                value: 2,
                label: Text('无限对话卡'),
              ),
            ],
            selected: {_cardType},
            onSelectionChanged: (value) {
              setState(() {
                _cardType = value.first;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_cardType == 1)
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '充值金额',
                border: OutlineInputBorder(),
                suffixText: '小懿币',
              ),
              keyboardType: TextInputType.number,
            )
          else
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: '无限对话时长',
                border: OutlineInputBorder(),
                suffixText: '小时',
              ),
              keyboardType: TextInputType.number,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _countController,
            decoration: const InputDecoration(
              labelText: '生成数量',
              border: OutlineInputBorder(),
              suffixText: '张',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final count = int.tryParse(_countController.text);
            if (count == null || count <= 0) {
              CustomSnackBar.show(context, message: '请输入有效的生成数量');
              return;
            }

            if (_cardType == 1) {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                CustomSnackBar.show(context, message: '请输入有效的充值金额');
                return;
              }
              Navigator.of(context).pop({
                'cardType': _cardType,
                'amount': amount,
                'count': count,
              });
            } else {
              final duration = int.tryParse(_durationController.text);
              if (duration == null || duration <= 0) {
                CustomSnackBar.show(context, message: '请输入有效的对话时长');
                return;
              }
              Navigator.of(context).pop({
                'cardType': _cardType,
                'duration': duration,
                'count': count,
              });
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
