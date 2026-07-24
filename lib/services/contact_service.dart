import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contact_model.dart';

class ContactService {
  /// Request contact read permission using permission_handler & flutter_contacts
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      return true;
    }
    return await FlutterContacts.requestPermission();
  }

  /// Check if contacts permission is granted
  Future<bool> hasPermission() async {
    return await Permission.contacts.isGranted ||
        await FlutterContacts.requestPermission(readonly: true);
  }

  /// Helper to format raw account type and account name into clean user-friendly labels
  static String formatAccountDisplayName(String rawName, String rawType) {
    final name = rawName.trim();
    final typeLower = rawType.trim().toLowerCase();

    if (typeLower.contains('google')) {
      return name.isNotEmpty ? 'Google ($name)' : 'Google Account';
    }
    if (typeLower.contains('sim')) {
      return (name.isNotEmpty && !name.startsWith('com.'))
          ? 'SIM Card ($name)'
          : 'SIM Card';
    }
    if (typeLower.contains('icloud')) {
      return name.isNotEmpty ? 'iCloud ($name)' : 'iCloud';
    }
    if (typeLower.contains('exchange')) {
      return name.isNotEmpty ? 'Exchange ($name)' : 'Exchange';
    }
    if (typeLower.contains('samsung') ||
        typeLower.contains('osp') ||
        typeLower.contains('sec')) {
      return name.isNotEmpty ? 'Samsung ($name)' : 'Samsung Account';
    }

    // General user account (e.g. email address or custom name)
    if (name.isNotEmpty && !name.startsWith('com.') && !name.startsWith('org.')) {
      return name;
    }

    return 'Device Local Storage';
  }

  /// Load all contacts from all device sources (Google, SIM, Local, etc.)
  Future<List<ExportableContact>> fetchAllContacts() async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception('Permission to read contacts was denied.');
    }

    // Fetch contacts with full properties and storage accounts metadata
    final rawContacts = await FlutterContacts.getContacts(
      withProperties: true,
      withAccounts: true,
    );

    final List<ExportableContact> exportableContacts = [];

    for (final c in rawContacts) {
      final firstName = c.name.first.trim();
      final lastName = c.name.last.trim();
      final displayName = c.displayName.trim().isNotEmpty
          ? c.displayName.trim()
          : '$firstName $lastName'.trim();

      // Determine storage account details
      String accName = 'Device Local Storage';
      String accType = 'local';
      String accKey = 'LOCAL_STORAGE';

      if (c.accounts.isNotEmpty) {
        final primaryAcc = c.accounts.first;
        final rawName = primaryAcc.name.trim();
        final rawType = primaryAcc.type.trim();

        accType = rawType;
        accName = formatAccountDisplayName(rawName, rawType);
        accKey = '${rawType.toUpperCase()}_${rawName.isNotEmpty ? rawName : "DEFAULT"}';
      }

      // If contact has multiple phone numbers, add rows for each number
      if (c.phones.isNotEmpty) {
        for (final p in c.phones) {
          final phoneNum = p.number.trim();
          if (phoneNum.isNotEmpty) {
            exportableContacts.add(
              ExportableContact(
                id: c.id,
                firstName: firstName,
                lastName: lastName,
                displayName: displayName.isNotEmpty ? displayName : phoneNum,
                phoneNumber: phoneNum,
                accountName: accName,
                accountType: accType,
                accountKey: accKey,
              ),
            );
          }
        }
      } else {
        // Contact without phone number
        exportableContacts.add(
          ExportableContact(
            id: c.id,
            firstName: firstName,
            lastName: lastName,
            displayName: displayName,
            phoneNumber: '',
            accountName: accName,
            accountType: accType,
            accountKey: accKey,
          ),
        );
      }
    }

    return exportableContacts;
  }

  /// Extract storage account sources with contact counts.
  /// Options with 0 contacts are hidden/excluded as required.
  List<ContactAccountSource> getAccountSources(List<ExportableContact> contacts) {
    final Map<String, ContactAccountSource> sourcesMap = {};

    for (final c in contacts) {
      if (!sourcesMap.containsKey(c.accountKey)) {
        sourcesMap[c.accountKey] = ContactAccountSource(
          key: c.accountKey,
          displayName: c.accountName,
          rawType: c.accountType,
          count: 1,
        );
      } else {
        final existing = sourcesMap[c.accountKey]!;
        sourcesMap[c.accountKey] = existing.copyWith(count: existing.count + 1);
      }
    }

    // Only include accounts with count > 0 (filters out 0 contact sources)
    final list = sourcesMap.values.where((s) => s.count > 0).toList();
    list.sort((a, b) => b.count.compareTo(a.count)); // Sort by highest count
    return list;
  }

  /// Apply text search match criteria and selected account source filter
  List<ExportableContact> filterContacts({
    required List<ExportableContact> contacts,
    required FilterOptions options,
  }) {
    return contacts.where((c) {
      // 1. Account source filter
      if (options.selectedAccountKey != 'ALL' &&
          c.accountKey != options.selectedAccountKey) {
        return false;
      }

      // 2. Text match filter (contains, startsWith, endsWith, exact)
      if (options.query.trim().isNotEmpty) {
        if (!c.matchesQuery(
          options.query,
          options.matchType,
          isCaseSensitive: options.isCaseSensitive,
        )) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Generate CSV file content from filtered contacts
  Future<File> generateCsvFile(List<ExportableContact> contacts) async {
    final List<List<dynamic>> csvData = [
      ['First Name', 'Last Name', 'Phone Number', 'Display Name', 'Account Source'],
    ];

    for (final c in contacts) {
      csvData.add([
        c.firstName,
        c.lastName,
        c.phoneNumber,
        c.displayName,
        c.accountName,
      ]);
    }

    final String csvContent = const ListToCsvConverter().convert(csvData);

    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'contacts_export_$timestamp.csv';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(csvContent);
    return file;
  }

  /// Open native platform share sheet for the generated CSV file
  Future<void> shareCsvFile(File file, {required int contactCount}) async {
    final xFile = XFile(file.path, mimeType: 'text/csv');
    await Share.shareXFiles(
      [xFile],
      subject: 'Contacts Export CSV ($contactCount contacts)',
      text: 'Here is the exported CSV file containing $contactCount contact(s).',
    );
  }
}
