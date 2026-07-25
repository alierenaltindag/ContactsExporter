import 'dart:io';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/contact_model.dart';
import '../models/import_model.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';

class ImportView extends StatefulWidget {
  final List<ExportableContact> existingContacts;
  final List<ContactAccountSource> accountSources;
  final AppLanguage currentLanguage;
  final VoidCallback onImportSuccess;

  const ImportView({
    super.key,
    required this.existingContacts,
    required this.accountSources,
    required this.currentLanguage,
    required this.onImportSuccess,
  });

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final ImportService _importService = ImportService();

  File? _selectedFile;
  String? _fileName;
  List<String> _headers = [];
  List<List<dynamic>> _dataRows = [];

  CsvColumnMapping _mapping = CsvColumnMapping();
  String _selectedAccountKey = 'LOCAL_STORAGE';
  String _selectedAccountName = 'Device Local Storage';
  bool _isSkipExisting = true;

  bool _isParsing = false;
  bool _isImporting = false;
  String? _errorMessage;

  AppTranslations get t => AppTranslations(widget.currentLanguage);

  @override
  void initState() {
    super.initState();
    if (widget.accountSources.isNotEmpty) {
      _selectedAccountKey = widget.accountSources.first.key;
      _selectedAccountName = widget.accountSources.first.displayName;
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });

    try {
      final file = await _importService.pickCsvFile();
      if (file == null) {
        setState(() => _isParsing = false);
        return;
      }

      final result = await _importService.parseCsvFile(file);

      setState(() {
        _selectedFile = file;
        _fileName = result['fileName'] as String;
        _headers = result['headers'] as List<String>;
        _dataRows = result['dataRows'] as List<List<dynamic>>;
        _mapping = result['mapping'] as CsvColumnMapping;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${t.errorOccurred}: $e';
        _isParsing = false;
      });
    }
  }

  Future<void> _startImportProcess() async {
    if (!_mapping.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.invalidMappingError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final record = await _importService.executeImport(
        dataRows: _dataRows,
        mapping: _mapping,
        targetAccountKey: _selectedAccountKey,
        targetAccountName: _selectedAccountName,
        isSkipExisting: _isSkipExisting,
        fileName: _fileName ?? 'import.csv',
        existingContacts: widget.existingContacts,
      );

      if (!mounted) return;
      setState(() {
        _isImporting = false;
      });

      _showSuccessDialog(record);
      widget.onImportSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '${t.errorOccurred}: $e';
        _isImporting = false;
      });
    }
  }

  void _showSuccessDialog(ImportHistoryRecord record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentEmerald.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentEmerald, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.importSuccessTitle,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          t.importSummary(record.addedCount, record.updatedCount, record.skippedCount),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step 1: Select CSV File
          _buildFilePickerCard(),
          const SizedBox(height: 16),

          if (_selectedFile != null) ...[
            // Step 2: Column Mapping
            _buildColumnMappingCard(),
            const SizedBox(height: 16),

            // Step 3: Target Account & Options
            _buildOptionsCard(),
            const SizedBox(height: 24),

            // Step 4: Submit Button
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _startImportProcess,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_upload_rounded),
              label: Text(
                _isImporting ? t.importingContacts : t.startImport,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_open_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.selectCsvFile,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedFile != null ? _fileName! : t.noFileSelected,
                      style: TextStyle(
                        color: _selectedFile != null
                            ? AppTheme.accentCyan
                            : AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isParsing ? null : _pickFile,
            icon: _isParsing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(_selectedFile == null ? t.selectCsvFile : t.changeCsvFile),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderDark),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 8),
            Text(
              t.rowsFound(_dataRows.length),
              style: const TextStyle(
                color: AppTheme.accentEmerald,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnMappingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.columnMappingTitle,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            t.columnMappingSub,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildMappingDropdown(
            label: t.mapPhone,
            value: _mapping.phoneIndex,
            isRequired: true,
            onChanged: (val) {
              setState(() => _mapping = _mapping.copyWith(phoneIndex: val));
            },
          ),
          const SizedBox(height: 12),
          _buildMappingDropdown(
            label: t.mapFirstName,
            value: _mapping.firstNameIndex,
            onChanged: (val) {
              setState(() => _mapping = _mapping.copyWith(firstNameIndex: val));
            },
          ),
          const SizedBox(height: 12),
          _buildMappingDropdown(
            label: t.mapLastName,
            value: _mapping.lastNameIndex,
            onChanged: (val) {
              setState(() => _mapping = _mapping.copyWith(lastNameIndex: val));
            },
          ),
          const SizedBox(height: 12),
          _buildMappingDropdown(
            label: t.mapDisplayName,
            value: _mapping.displayNameIndex,
            onChanged: (val) {
              setState(() => _mapping = _mapping.copyWith(displayNameIndex: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMappingDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int?>(
          initialValue: value != null && value < _headers.length ? value : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderDark),
            ),
          ),
          dropdownColor: AppTheme.surfaceDark,
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(t.ignoreColumn,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
            ...List.generate(_headers.length, (i) {
              return DropdownMenuItem<int?>(
                value: i,
                child: Text(
                  '${_headers[i]} (Sütun ${i + 1})',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Storage Account Selection
          Text(
            t.targetAccountTitle,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedAccountKey,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderDark),
              ),
            ),
            dropdownColor: AppTheme.surfaceDark,
            items: widget.accountSources.map((s) {
              return DropdownMenuItem<String>(
                value: s.key,
                child: Text(
                  s.displayName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final source = widget.accountSources.firstWhere((s) => s.key == val);
                setState(() {
                  _selectedAccountKey = val;
                  _selectedAccountName = source.displayName;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Checkbox: Skip Existing Numbers with Tooltip
          InkWell(
            onTap: () {
              setState(() => _isSkipExisting = !_isSkipExisting);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: _isSkipExisting,
                    onChanged: (val) {
                      setState(() => _isSkipExisting = val ?? true);
                    },
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.skipExistingNumbers,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Tooltip(
                  message: t.skipExistingTooltip,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  showDuration: const Duration(seconds: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  textStyle:
                      const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.accentCyan,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
