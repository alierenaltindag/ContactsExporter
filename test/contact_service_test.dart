import 'package:contacts_exporter/models/contact_model.dart';
import 'package:contacts_exporter/services/contact_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Contact Account Display Name Formatting', () {
    test('formatAccountDisplayName cleans up raw package names', () {
      expect(
        ContactService.formatAccountDisplayName(
          'alierenaltindaag@gmail.com',
          'com.osp.app.signin',
        ),
        equals('Samsung (alierenaltindaag@gmail.com)'),
      );

      expect(
        ContactService.formatAccountDisplayName(
          'user@gmail.com',
          'com.google',
        ),
        equals('Google (user@gmail.com)'),
      );

      expect(
        ContactService.formatAccountDisplayName(
          '',
          'com.android.contacts.sim',
        ),
        equals('SIM Card'),
      );
    });
  });

  group('Contact Matching Logic Tests (Merged Full Name Evaluation)', () {
    final contactRhs = ExportableContact(
      id: '1',
      firstName: 'Ahmet',
      lastName: 'Yılmaz RHS',
      displayName: 'Ahmet Yılmaz RHS',
      phoneNumber: '+905551234567',
      accountName: 'Google (user@gmail.com)',
      accountType: 'com.google',
      accountKey: 'GOOGLE_user@gmail.com',
    );

    final contactAsd = ExportableContact(
      id: '2',
      firstName: 'ASD Mehmet',
      lastName: 'Kaya',
      displayName: 'ASD Mehmet Kaya',
      phoneNumber: '+905559876543',
      accountName: 'SIM Card',
      accountType: 'com.android.contacts.sim',
      accountKey: 'SIM_DEFAULT',
    );

    final contactTr = ExportableContact(
      id: '3',
      firstName: 'İsmail',
      lastName: 'Şahin RHS',
      displayName: 'İsmail Şahin RHS',
      phoneNumber: '+905550001122',
      accountName: 'Device Storage',
      accountType: 'local',
      accountKey: 'LOCAL_STORAGE',
    );

    test('Contains filter match', () {
      expect(contactRhs.matchesQuery('RHS', SearchMatchType.contains), isTrue);
      expect(contactRhs.matchesQuery('rhs', SearchMatchType.contains), isTrue);
      expect(contactRhs.matchesQuery('Yılmaz', SearchMatchType.contains), isTrue);
      expect(contactAsd.matchesQuery('RHS', SearchMatchType.contains), isFalse);
      expect(contactTr.matchesQuery('ismail', SearchMatchType.contains), isTrue);
      expect(contactTr.matchesQuery('İsmail', SearchMatchType.contains), isTrue);
    });

    test('Starts With filter match (Evaluates full merged string start)', () {
      expect(contactAsd.matchesQuery('ASD', SearchMatchType.startsWith), isTrue);
      expect(contactAsd.matchesQuery('asd', SearchMatchType.startsWith), isTrue);
      expect(contactAsd.matchesQuery('ASD Mehmet', SearchMatchType.startsWith), isTrue);
      expect(contactAsd.matchesQuery('Kaya', SearchMatchType.startsWith), isFalse);
      expect(contactAsd.matchesQuery('Mehmet', SearchMatchType.startsWith), isFalse);
      expect(contactRhs.matchesQuery('Ahmet', SearchMatchType.startsWith), isTrue);
      expect(contactRhs.matchesQuery('RHS', SearchMatchType.startsWith), isFalse);
    });

    test('Ends With filter match (Evaluates full merged string end)', () {
      expect(contactRhs.matchesQuery('RHS', SearchMatchType.endsWith), isTrue);
      expect(contactRhs.matchesQuery('rhs', SearchMatchType.endsWith), isTrue);
      expect(contactRhs.matchesQuery('Yılmaz RHS', SearchMatchType.endsWith), isTrue);
      expect(contactRhs.matchesQuery('Ahmet', SearchMatchType.endsWith), isFalse);
      expect(contactRhs.matchesQuery('Yılmaz', SearchMatchType.endsWith), isFalse);
      expect(contactAsd.matchesQuery('Kaya', SearchMatchType.endsWith), isTrue);
      expect(contactAsd.matchesQuery('ASD', SearchMatchType.endsWith), isFalse);
    });

    test('Exact match (Evaluates full merged string exact equality)', () {
      expect(contactRhs.matchesQuery('Ahmet Yılmaz RHS', SearchMatchType.exact), isTrue);
      expect(contactRhs.matchesQuery('ahmet yılmaz rhs', SearchMatchType.exact), isTrue);
      expect(contactRhs.matchesQuery('Ahmet', SearchMatchType.exact), isFalse);
      expect(contactRhs.matchesQuery('RHS', SearchMatchType.exact), isFalse);
    });

    test('Case sensitivity filter test', () {
      // Case insensitive (default false): 'rhs' matches 'Ahmet Yılmaz RHS'
      expect(contactRhs.matchesQuery('rhs', SearchMatchType.endsWith, isCaseSensitive: false), isTrue);

      // Case sensitive (isCaseSensitive: true): 'rhs' does NOT match 'RHS'
      expect(contactRhs.matchesQuery('rhs', SearchMatchType.endsWith, isCaseSensitive: true), isFalse);
      expect(contactRhs.matchesQuery('RHS', SearchMatchType.endsWith, isCaseSensitive: true), isTrue);

      // Starts with case sensitive
      expect(contactRhs.matchesQuery('ahmet', SearchMatchType.startsWith, isCaseSensitive: true), isFalse);
      expect(contactRhs.matchesQuery('Ahmet', SearchMatchType.startsWith, isCaseSensitive: true), isTrue);
    });
  });

  group('Contact Account Filtering & Counting', () {
    final service = ContactService();

    final contacts = [
      ExportableContact(
        id: '1',
        firstName: 'User1',
        lastName: 'Google',
        displayName: 'User1 Google',
        phoneNumber: '11111',
        accountName: 'Google (work@gmail.com)',
        accountType: 'com.google',
        accountKey: 'GOOGLE_work@gmail.com',
      ),
      ExportableContact(
        id: '2',
        firstName: 'User2',
        lastName: 'Google',
        displayName: 'User2 Google',
        phoneNumber: '22222',
        accountName: 'Google (work@gmail.com)',
        accountType: 'com.google',
        accountKey: 'GOOGLE_work@gmail.com',
      ),
      ExportableContact(
        id: '3',
        firstName: 'User3',
        lastName: 'SIM',
        displayName: 'User3 SIM',
        phoneNumber: '33333',
        accountName: 'SIM Card',
        accountType: 'com.sim',
        accountKey: 'SIM_CARD',
      ),
    ];

    test('getAccountSources groups and counts correctly', () {
      final sources = service.getAccountSources(contacts);

      expect(sources.length, equals(2));
      final googleSource = sources.firstWhere((s) => s.key == 'GOOGLE_work@gmail.com');
      expect(googleSource.count, equals(2));

      final simSource = sources.firstWhere((s) => s.key == 'SIM_CARD');
      expect(simSource.count, equals(1));
    });

    test('filterContacts filters by account key correctly', () {
      final filteredGoogle = service.filterContacts(
        contacts: contacts,
        options: const FilterOptions(selectedAccountKey: 'GOOGLE_work@gmail.com'),
      );
      expect(filteredGoogle.length, equals(2));

      final filteredSim = service.filterContacts(
        contacts: contacts,
        options: const FilterOptions(selectedAccountKey: 'SIM_CARD'),
      );
      expect(filteredSim.length, equals(1));
    });
  });
}
