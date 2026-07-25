import 'package:contacts_exporter/models/contact_model.dart';
import 'package:contacts_exporter/models/import_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phone Number Normalization Tests', () {
    test('Normalizes numbers by stripping non-digits except leading +', () {
      expect(ExportableContact.normalizePhone('+90 555 123 45 67'), equals('+905551234567'));
      expect(ExportableContact.normalizePhone('0555-123-4567'), equals('05551234567'));
      expect(ExportableContact.normalizePhone('(555) 123 4567'), equals('5551234567'));
      expect(ExportableContact.normalizePhone(''), equals(''));
    });
  });

  group('CSV Column Mapping Tests', () {
    test('isValid returns true when phone and name fields are mapped', () {
      final validMapping = CsvColumnMapping(
        phoneIndex: 2,
        firstNameIndex: 0,
        lastNameIndex: 1,
      );
      expect(validMapping.isValid, isTrue);

      final invalidMappingNoPhone = CsvColumnMapping(
        firstNameIndex: 0,
        lastNameIndex: 1,
      );
      expect(invalidMappingNoPhone.isValid, isFalse);

      final invalidMappingNoName = CsvColumnMapping(
        phoneIndex: 2,
      );
      expect(invalidMappingNoName.isValid, isFalse);
    });
  });

  group('ImportHistoryRecord Serialization Tests', () {
    test('ImportHistoryRecord serializes to and from JSON correctly', () {
      final now = DateTime.now();
      final record = ImportHistoryRecord(
        id: '123456789',
        timestamp: now,
        fileName: 'contacts_sample.csv',
        totalRows: 50,
        addedCount: 40,
        updatedCount: 8,
        skippedCount: 2,
        targetAccountKey: 'GOOGLE_test@gmail.com',
        targetAccountName: 'Google (test@gmail.com)',
        isSkipExisting: true,
        backupFilePath: '/app/backups/backup_123.json',
        createdContactIds: ['id1', 'id2', 'id3'],
      );

      final jsonMap = record.toJson();
      final restored = ImportHistoryRecord.fromJson(jsonMap);

      expect(restored.id, equals(record.id));
      expect(restored.fileName, equals(record.fileName));
      expect(restored.totalRows, equals(record.totalRows));
      expect(restored.addedCount, equals(record.addedCount));
      expect(restored.updatedCount, equals(record.updatedCount));
      expect(restored.skippedCount, equals(record.skippedCount));
      expect(restored.targetAccountKey, equals(record.targetAccountKey));
      expect(restored.isSkipExisting, equals(record.isSkipExisting));
      expect(restored.createdContactIds, equals(record.createdContactIds));
    });
  });
}
