import '../l10n/app_localizations.dart';

enum SearchMatchType {
  contains,
  startsWith,
  endsWith,
  exact;

  String getLabel(dynamic t) {
    switch (this) {
      case SearchMatchType.contains:
        return t.contains;
      case SearchMatchType.startsWith:
        return t.startsWith;
      case SearchMatchType.endsWith:
        return t.endsWith;
      case SearchMatchType.exact:
        return t.exactMatch;
    }
  }

  String get label => getLabel(AppTranslations(AppLanguage.en));
}

class ExportableContact {
  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String phoneNumber;
  final String accountName;
  final String accountType;
  final String accountKey;

  late final String fullCombinedName;
  late final String normFullNameLower;
  late final String normFullNameCase;
  late final String normPhoneLower;
  late final String normPhoneCase;

  ExportableContact({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.phoneNumber,
    required this.accountName,
    required this.accountType,
    required this.accountKey,
  }) {
    fullCombinedName = displayName.trim().isNotEmpty
        ? displayName.trim()
        : '$firstName $lastName'.trim();

    normFullNameCase = fullCombinedName;
    normFullNameLower = _normalize(fullCombinedName);

    normPhoneCase = phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
    normPhoneLower = _normalize(phoneNumber).replaceAll(RegExp(r'\s+'), '');
  }

  static String _normalize(String input) {
    return input
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç')
        .toLowerCase();
  }

  /// Normalizes phone numbers by removing spaces, hyphens, brackets, and non-digit chars (except leading '+')
  static String normalizePhone(String phone) {
    if (phone.isEmpty) return '';
    final trimmed = phone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }

  /// Check if the full merged contact name matches the query string based on match type and case sensitivity
  bool matchesQuery(
    String query,
    SearchMatchType matchType, {
    bool isCaseSensitive = false,
  }) {
    if (query.trim().isEmpty) return true;
    final cleanQuery = isCaseSensitive ? query.trim() : _normalize(query);
    if (cleanQuery.isEmpty) return true;

    final targetName = isCaseSensitive ? normFullNameCase : normFullNameLower;
    final targetPhone = isCaseSensitive ? normPhoneCase : normPhoneLower;

    switch (matchType) {
      case SearchMatchType.contains:
        return targetName.contains(cleanQuery) || targetPhone.contains(cleanQuery);

      case SearchMatchType.startsWith:
        return targetName.startsWith(cleanQuery);

      case SearchMatchType.endsWith:
        return targetName.endsWith(cleanQuery);

      case SearchMatchType.exact:
        return targetName == cleanQuery;
    }
  }
}

class ContactAccountSource {
  final String key;
  final String displayName;
  final String rawType;
  final int count;

  ContactAccountSource({
    required this.key,
    required this.displayName,
    required this.rawType,
    required this.count,
  });

  ContactAccountSource copyWith({int? count}) {
    return ContactAccountSource(
      key: key,
      displayName: displayName,
      rawType: rawType,
      count: count ?? this.count,
    );
  }
}

class FilterOptions {
  final String query;
  final SearchMatchType matchType;
  final String selectedAccountKey;
  final bool isCaseSensitive;

  const FilterOptions({
    this.query = '',
    this.matchType = SearchMatchType.contains,
    this.selectedAccountKey = 'ALL',
    this.isCaseSensitive = false,
  });

  FilterOptions copyWith({
    String? query,
    SearchMatchType? matchType,
    String? selectedAccountKey,
    bool? isCaseSensitive,
  }) {
    return FilterOptions(
      query: query ?? this.query,
      matchType: matchType ?? this.matchType,
      selectedAccountKey: selectedAccountKey ?? this.selectedAccountKey,
      isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
    );
  }
}
