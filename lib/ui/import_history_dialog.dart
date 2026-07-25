import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/import_model.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';

class ImportHistoryDialog extends StatefulWidget {
  final AppLanguage currentLanguage;
  final VoidCallback onRollbackSuccess;

  const ImportHistoryDialog({
    super.key,
    required this.currentLanguage,
    required this.onRollbackSuccess,
  });

  @override
  State<ImportHistoryDialog> createState() => _ImportHistoryDialogState();
}

class _ImportHistoryDialogState extends State<ImportHistoryDialog> {
  final ImportService _importService = ImportService();

  List<ImportHistoryRecord> _records = [];
  bool _isLoading = true;
  String? _processingId;

  AppTranslations get t => AppTranslations(widget.currentLanguage);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await _importService.fetchHistory();
    setState(() {
      _records = list;
      _isLoading = false;
    });
  }

  Future<void> _confirmAndRollback(ImportHistoryRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.undoConfirmTitle,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          t.undoConfirmMsg,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderDark),
            ),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text(t.undoImport),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _processingId = record.id);
      final success = await _importService.rollbackImport(record);
      setState(() => _processingId = null);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.undoSuccess),
            backgroundColor: AppTheme.accentEmerald,
          ),
        );
        _loadHistory();
        widget.onRollbackSuccess();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderDark),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 550, maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.importHistory,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppTheme.borderDark, height: 24),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                      ? Center(
                          child: Text(
                            t.noHistoryFound,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _records.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            final isBusy = _processingId == record.id;
                            final dateStr = DateFormat('yyyy-MM-dd HH:mm')
                                .format(record.timestamp);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          record.fileName,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    record.targetAccountName,
                                    style: const TextStyle(
                                      color: AppTheme.accentCyan,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _buildBadge(
                                          '+${record.addedCount}',
                                          AppTheme.accentEmerald),
                                      const SizedBox(width: 6),
                                      _buildBadge(
                                          '~${record.updatedCount}',
                                          Colors.amber),
                                      const SizedBox(width: 6),
                                      _buildBadge(
                                          'ø${record.skippedCount}',
                                          AppTheme.textMuted),
                                      const Spacer(),
                                      OutlinedButton.icon(
                                        onPressed: isBusy
                                            ? null
                                            : () => _confirmAndRollback(record),
                                        icon: isBusy
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2),
                                              )
                                            : const Icon(Icons.undo_rounded,
                                                size: 16),
                                        label: Text(
                                          t.undoImport,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(
                                              color: Colors.redAccent),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
