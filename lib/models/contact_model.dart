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

  ExportableContact({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.phoneNumber,
    required this.accountName,
    required this.accountType,
    required this.accountKey,
  });

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

  /// Check if the full merged contact name matches the query string based on match type and case sensitivity
  bool matchesQuery(
    String query,
    SearchMatchType matchType, {
    bool isCaseSensitive = false,
  }) {
    final cleanQuery = isCaseSensitive ? query.trim() : _normalize(query);
    if (cleanQuery.isEmpty) return true;

    // Full merged name string (e.g. "Ahmet Yılmaz RHS")
    final String combinedName = displayName.trim().isNotEmpty
        ? displayName.trim()
        : '$firstName $lastName'.trim();

    final normFullName =
        isCaseSensitive ? combinedName : _normalize(combinedName);
    final normAltName = isCaseSensitive
        ? '$firstName $lastName'.trim()
        : _normalize('$firstName $lastName'.trim());
    final normPhone = isCaseSensitive
        ? phoneNumber.trim().replaceAll(RegExp(r'\s+'), '')
        : _normalize(phoneNumber).replaceAll(RegExp(r'\s+'), '');

    switch (matchType) {
      case SearchMatchType.contains:
        return normFullName.contains(cleanQuery) ||
            normAltName.contains(cleanQuery) ||
            normPhone.contains(cleanQuery);

      case SearchMatchType.startsWith:
        return normFullName.startsWith(cleanQuery) ||
            (normAltName.isNotEmpty && normAltName.startsWith(cleanQuery));

      case SearchMatchType.endsWith:
        return normFullName.endsWith(cleanQuery) ||
            (normAltName.isNotEmpty && normAltName.endsWith(cleanQuery));

      case SearchMatchType.exact:
        return normFullName == cleanQuery ||
            (normAltName.isNotEmpty && normAltName == cleanQuery);
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
