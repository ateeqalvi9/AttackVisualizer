/// Session Logs & Mathematical Presets Drawer
library;

import 'package:flutter/material.dart';
import '../../core/storage/history_repository.dart';
import '../../shared/theme/app_colors.dart';

class HistoryDrawer extends StatefulWidget {
  final ValueChanged<String> onSelectExpression;

  const HistoryDrawer({super.key, required this.onSelectExpression});

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  List<HistoryRecord> _records = [];
  bool _loading = true;

  final List<Map<String, String>> _presets = [
    {'label': 'Cubic Solver', 'expr': 'x^3 - 6x^2 + 11x - 6'},
    {'label': 'Damped Sine Wave', 'expr': 'exp(-0.2x) * sin(2x)'},
    {'label': 'Gaussian Curve', 'expr': 'exp(-x^2)'},
    {'label': 'Newton Limit', 'expr': '(exp(x) - 1) / x'},
    {'label': 'Saddle Surface', 'expr': 'x^2 - y^2'},
    {'label': 'Gaussian 3D', 'expr': '3 * exp(-(x^2 + y^2) / 4)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await HistoryRepository.getHistory();
    if (mounted) {
      setState(() {
        _records = list;
        _loading = false;
      });
    }
  }

  Future<void> _deleteRecord(String id) async {
    await HistoryRepository.deleteHistory(id);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    await HistoryRepository.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, size: 20, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'Session Logs',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (_records.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.delete_sweep, size: 16),
                      label: const Text('Clear', style: TextStyle(fontSize: 11)),
                      onPressed: _clearAll,
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),

            // Presets Playgrounds Section
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text(
                        'PRESETS PLAYGROUNDS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _presets.map((p) {
                      return GestureDetector(
                        onTap: () {
                          widget.onSelectExpression(p['expr']!);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            p['label']!,
                            style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Log Items List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _records.isEmpty
                      ? const Center(
                          child: Text(
                            'No computation history yet',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, idx) {
                            final rec = _records[idx];
                            return Material(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  widget.onSelectExpression(rec.expression);
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          rec.type.toUpperCase(),
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rec.expression,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'monospace',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '= ${rec.result}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.success,
                                                fontFamily: 'monospace',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _deleteRecord(rec.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
