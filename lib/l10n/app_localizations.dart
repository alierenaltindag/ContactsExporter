enum AppLanguage {
  en('English', '🇺🇸'),
  tr('Türkçe', '🇹🇷');

  final String label;
  final String flag;

  const AppLanguage(this.label, this.flag);
}

class AppTranslations {
  final AppLanguage language;

  AppTranslations(this.language);

  bool get isTurkish => language == AppLanguage.tr;

  // Title & Subtitle
  String get appTitle => isTurkish ? 'Rehber Dışa Aktarıcı' : 'Contacts Exporter';
  String get appSubtitle => isTurkish ? 'Rehberi Tara, Filtrele ve CSV Aktar' : 'Scan, Filter & Export CSV';

  // Stats
  String get totalContacts => isTurkish ? 'TOPLAM REHBER' : 'TOTAL CONTACTS';
  String get filteredResult => isTurkish ? 'FİLTRELENEN REHBER' : 'FILTERED RESULT';
  String sourcesCount(int count) => isTurkish ? '$count Kaynak' : '$count Sources';

  // Storage Source
  String get storageSourceLabel => isTurkish ? 'Depolama Kaynağı / Hesap' : 'Storage Source / Account';
  String allSources(int count) => isTurkish ? 'Tüm Kaynaklar ($count)' : 'All Sources ($count)';
  String get selectStorageSource => isTurkish ? 'Depolama Kaynağı Seçin' : 'Select Storage Source';

  // Search & Match
  String get searchHint => isTurkish ? 'İsme göre ara (ör. RHS, ASD)...' : 'Search by name (e.g. RHS, ASD)...';
  String get matchModeLabel => isTurkish ? 'Eşleşme Modu' : 'Match Criteria';
  String get contains => isTurkish ? 'İçerir' : 'Contains';
  String get startsWith => isTurkish ? 'İle Başlar' : 'Starts With';
  String get endsWith => isTurkish ? 'İle Biter' : 'Ends With';
  String get exactMatch => isTurkish ? 'Tam Eşleşme' : 'Exact Match';
  String get caseSensitive => isTurkish ? 'Büyük/Küçük Harf Duyarlı' : 'Case Sensitive';

  // Contacts List
  String matchedContacts(int count) => isTurkish ? 'Eşleşen Rehber Kayıtları ($count)' : 'Matched Contacts ($count)';
  String get resetFilters => isTurkish ? 'Filtreleri Sıfırla' : 'Reset Filters';
  String get noContactsFound => isTurkish ? 'Rehber Kaydı Bulunamadı' : 'No contacts found';
  String get emptyStateSub => isTurkish
      ? 'Arama metnini, eşleşme kriterini veya depolama kaynağını değiştirmeyi deneyin.'
      : 'Try adjusting your search query, match criteria, or storage source.';
  String get noPhone => isTurkish ? 'Telefon Numarası Yok' : 'No Phone Number';

  // Actions & Buttons
  String exportCsv(int count) => isTurkish ? 'CSV Olarak Aktar ($count)' : 'Export CSV ($count)';
  String get exportingCsv => isTurkish ? 'CSV Aktarılıyor...' : 'Exporting CSV...';
  String get shareCsv => isTurkish ? 'CSV Paylaş' : 'Share CSV';
  String get shareCsvFile => isTurkish ? 'CSV Dosyasını Paylaş' : 'Share CSV File';
  String get close => isTurkish ? 'Kapat' : 'Close';
  String get rescanTooltip => isTurkish ? 'Rehberi Yeniden Tara' : 'Rescan Contacts';

  // Dialog & Success
  String get exportSuccess => isTurkish ? 'CSV Başarıyla Dışa Aktarıldı!' : 'CSV Exported Successfully!';
  String exportedCountMsg(int count) => isTurkish
      ? '$count rehber kaydı CSV formatında başarıyla hazırlandı.'
      : 'Exported $count contacts to CSV format.';
  String get noMatchesToExport => isTurkish ? 'Filtrenize uyan rehber kaydı bulunamadı.' : 'No contacts match your filter criteria.';
  String get permissionDeniedMsg => isTurkish ? 'Rehberi aktarmak için rehber erişim izni gereklidir.' : 'Contacts permission is required to export contacts.';

  // Permission View
  String get permissionTitle => isTurkish ? 'Rehber Erişimi Gerekli' : 'Contacts Access Required';
  String get permissionDesc => isTurkish
      ? 'Google hesaplarınız, SIM kartınız ve cihaz hafızasındaki rehberinizi tarayıp aktarabilmek için lütfen rehber erişim izni verin.'
      : 'To scan and export contacts from your Google accounts, SIM card, and device storage, please grant contacts read permission.';
  String get grantAccess => isTurkish ? 'Erişim İzni Ver' : 'Grant Access';

  // Loading & Errors
  String get scanningContacts => isTurkish ? 'Rehber ve depolama hesapları taranıyor...' : 'Scanning contacts & storage accounts...';
  String get errorOccurred => isTurkish ? 'Bir hata oluştu' : 'An error occurred';
  String get retry => isTurkish ? 'Tekrar Dene' : 'Retry';

  // CSV Headers
  String get csvHeaderFirstName => isTurkish ? 'İsim' : 'First Name';
  String get csvHeaderLastName => isTurkish ? 'Soyisim' : 'Last Name';
  String get csvHeaderPhone => isTurkish ? 'Telefon Numarası' : 'Phone Number';
  String get csvHeaderDisplayName => isTurkish ? 'Görünen İsim' : 'Display Name';
  String get csvHeaderAccount => isTurkish ? 'Hesap Kaynağı' : 'Account Source';
}
