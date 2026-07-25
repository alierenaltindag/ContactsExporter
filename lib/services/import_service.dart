import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/contact_model.dart';
import '../models/import_model.dart';

class ImportService {
  static const String _historyFileName = 'import_history.json';

  /// Pick a CSV file from storage using file_picker
  Future<File?> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Read CSV file and parse into rows and headers
  Future<Map<String, dynamic>> parseCsvFile(File file) async {
    final content = await file.readAsString();

    // Standardize line endings and parse CSV content
    final cleanContent = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(cleanContent);

    if (rows.isEmpty) {
      throw Exception('CSV file is empty');
    }

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.sublist(1).where((r) => r.any((c) => c.toString().trim().isNotEmpty)).toList();

    // Auto-detect best matching column indices
    final mapping = _autoDetectMapping(headers);

    return {
      'headers': headers,
      'dataRows': dataRows,
      'mapping': mapping,
      'fileName': file.path.split(Platform.pathSeparator).last,
    };
  }

  /// Auto-detect column mapping based on common header names
  CsvColumnMapping _autoDetectMapping(List<String> headers) {
    int? firstNameIdx;
    int? lastNameIdx;
    int? phoneIdx;
    int? displayNameIdx;

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();

      if (h.contains('phone') || h.contains('tel') || h.contains('mobile') || h.contains('numara')) {
        phoneIdx ??= i;
      } else if (h.contains('first') || h.contains('isim') || h.contains('ad') && !h.contains('soy')) {
        firstNameIdx ??= i;
      } else if (h.contains('last') || h.contains('soy')) {
        lastNameIdx ??= i;
      } else if (h.contains('display') || h.contains('görünen')) {
        displayNameIdx ??= i;
      } else if (h == 'name' || h == 'isim') {
        displayNameIdx ??= i;
      }
    }

    // Fallbacks
    if (firstNameIdx == null && displayNameIdx == null && headers.isNotEmpty) {
      firstNameIdx = 0;
    }
    if (phoneIdx == null && headers.length > 1) {
      phoneIdx = headers.length > 2 ? 2 : 1;
    }

    return CsvColumnMapping(
      firstNameIndex: firstNameIdx,
      lastNameIndex: lastNameIdx,
      phoneIndex: phoneIdx,
      displayNameIndex: displayNameIdx,
    );
  }

  /// Create a full JSON backup of all existing contacts before import
  Future<File> createFullBackup(List<ExportableContact> currentContacts) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFile = File('${backupDir.path}/contacts_backup_$timestamp.json');

    final jsonList = currentContacts.map((c) => {
      'id': c.id,
      'firstName': c.firstName,
      'lastName': c.lastName,
      'displayName': c.displayName,
      'phoneNumber': c.phoneNumber,
      'accountName': c.accountName,
      'accountType': c.accountType,
      'accountKey': c.accountKey,
    }).toList();

    await backupFile.writeAsString(jsonEncode(jsonList));
    return backupFile;
  }

  /// Execute Contact Import with duplicate check & override logic
  Future<ImportHistoryRecord> executeImport({
    required List<List<dynamic>> dataRows,
    required CsvColumnMapping mapping,
    required String targetAccountKey,
    required String targetAccountName,
    required bool isSkipExisting,
    required String fileName,
    required List<ExportableContact> existingContacts,
  }) async {
    // Ensure write contacts permission is granted before executing import operations
    final hasWritePerm = await FlutterContacts.requestPermission(readonly: false);
    if (!hasWritePerm) {
      throw Exception('Rehber yazma izni alınamadı.');
    }

    // 1. Create Backup before starting import
    final backupFile = await createFullBackup(existingContacts);

    // 2. Pre-index existing contacts by normalized phone number
    final Map<String, Contact> fullNativeContactsMap = {};
    Account? targetNativeAccount;

    try {
      final nativeContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withAccounts: true,
        withThumbnail: false,
        withPhoto: false,
        withGroups: false,
      );
      for (final nc in nativeContacts) {
        if (targetNativeAccount == null && nc.accounts.isNotEmpty) {
          for (final acc in nc.accounts) {
            final accKey = '${acc.type.toUpperCase()}_${acc.name.isNotEmpty ? acc.name : "DEFAULT"}';
            if (accKey == targetAccountKey) {
              targetNativeAccount = acc;
              break;
            }
          }
        }
        for (final p in nc.phones) {
          final norm = ExportableContact.normalizePhone(p.number);
          if (norm.isNotEmpty) {
            fullNativeContactsMap[norm] = nc;
          }
        }
      }
    } catch (_) {}

    int addedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;
    final List<String> createdContactIds = [];

    for (final row in dataRows) {
      try {
        String rawPhone = '';
        String rawFirst = '';
        String rawLast = '';
        String rawDisplay = '';

        if (mapping.phoneIndex != null &&
            mapping.phoneIndex! >= 0 &&
            mapping.phoneIndex! < row.length) {
          rawPhone = (row[mapping.phoneIndex!] ?? '').toString().trim();
        }
        if (mapping.firstNameIndex != null &&
            mapping.firstNameIndex! >= 0 &&
            mapping.firstNameIndex! < row.length) {
          rawFirst = (row[mapping.firstNameIndex!] ?? '').toString().trim();
        }
        if (mapping.lastNameIndex != null &&
            mapping.lastNameIndex! >= 0 &&
            mapping.lastNameIndex! < row.length) {
          rawLast = (row[mapping.lastNameIndex!] ?? '').toString().trim();
        }
        if (mapping.displayNameIndex != null &&
            mapping.displayNameIndex! >= 0 &&
            mapping.displayNameIndex! < row.length) {
          rawDisplay = (row[mapping.displayNameIndex!] ?? '').toString().trim();
        }

        if (rawFirst.isEmpty && rawLast.isEmpty && rawDisplay.isNotEmpty) {
          final parts = rawDisplay.split(' ');
          rawFirst = parts.first;
          if (parts.length > 1) {
            rawLast = parts.sublist(1).join(' ');
          }
        }

        final normalizedPhone = ExportableContact.normalizePhone(rawPhone);
        if (normalizedPhone.isEmpty) {
          skippedCount++;
          continue;
        }

        final existingNative = fullNativeContactsMap[normalizedPhone];

        if (isSkipExisting && existingNative != null) {
          // Skip adding new phone, BUT override Name & Surname
          try {
            existingNative.name.first = rawFirst.isNotEmpty ? rawFirst : existingNative.name.first;
            existingNative.name.last = rawLast.isNotEmpty ? rawLast : existingNative.name.last;
            await FlutterContacts.updateContact(existingNative);
            updatedCount++;
          } catch (_) {
            skippedCount++;
          }
        } else {
          // Create new contact
          try {
            final newContact = Contact(
              name: Name(first: rawFirst, last: rawLast),
              phones: [Phone(rawPhone)],
              accounts: targetNativeAccount != null ? [targetNativeAccount] : [],
            );
            final inserted = await FlutterContacts.insertContact(newContact);
            if (inserted.id.isNotEmpty) {
              createdContactIds.add(inserted.id);
            }
            addedCount++;
          } catch (_) {
            skippedCount++;
          }
        }
      } catch (_) {
        skippedCount++;
      }
    }

    // 3. Create Import History Record
    final record = ImportHistoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      fileName: fileName,
      totalRows: dataRows.length,
      addedCount: addedCount,
      updatedCount: updatedCount,
      skippedCount: skippedCount,
      targetAccountKey: targetAccountKey,
      targetAccountName: targetAccountName,
      isSkipExisting: isSkipExisting,
      backupFilePath: backupFile.path,
      createdContactIds: createdContactIds,
    );

    await _saveHistoryRecord(record);
    return record;
  }

  /// Load all past import history records from local JSON
  Future<List<ImportHistoryRecord>> fetchHistory() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_historyFileName');
    if (!file.existsSync()) return [];

    try {
      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final records = jsonList.map((j) => ImportHistoryRecord.fromJson(j as Map<String, dynamic>)).toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (_) {
      return [];
    }
  }

  /// Save an import history record to local JSON
  Future<void> _saveHistoryRecord(ImportHistoryRecord record) async {
    final history = await fetchHistory();
    history.insert(0, record);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_historyFileName');
    final jsonList = history.map((h) => h.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Rollback an import operation (deletes created contacts and updates history)
  Future<bool> rollbackImport(ImportHistoryRecord record) async {
    try {
      // 1. Delete contacts created during this import
      for (final contactId in record.createdContactIds) {
        try {
          final c = await FlutterContacts.getContact(contactId);
          if (c != null) {
            await FlutterContacts.deleteContact(c);
          }
        } catch (_) {}
      }

      // 2. Remove record from history
      final history = await fetchHistory();
      history.removeWhere((h) => h.id == record.id);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_historyFileName');
      final jsonList = history.map((h) => h.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      return true;
    } catch (_) {
      return false;
    }
  }
}
