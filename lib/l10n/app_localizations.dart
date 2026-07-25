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
  String get appTitle => isTurkish ? 'Rehber Aktarıcı' : 'Contacts Exporter';
  String get appSubtitle => isTurkish ? 'Rehberi Tara, Filtrele ve CSV Aktar' : 'Scan, Filter & Export CSV';

  // Mode Switcher
  String get exportTab => isTurkish ? 'Dışa Aktar' : 'Export';
  String get importTab => isTurkish ? 'İçe Aktar' : 'Import';

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

  // Import Feature Localization
  String get selectCsvFile => isTurkish ? 'CSV Dosyası Seç' : 'Select CSV File';
  String get changeCsvFile => isTurkish ? 'Farklı CSV Seç' : 'Change CSV File';
  String get noFileSelected => isTurkish ? 'Henüz CSV dosyası seçilmedi' : 'No CSV file selected';
  String rowsFound(int count) => isTurkish ? '$count Satır Bulundu' : '$count Rows Found';
  String get columnMappingTitle => isTurkish ? 'Sütun Eşleştirme' : 'Column Mapping';
  String get columnMappingSub => isTurkish
      ? 'CSV dosyanızdaki sütunları rehber alanlarıyla eşleştirin.'
      : 'Match your CSV columns with contact fields.';
  String get mapFirstName => isTurkish ? 'İsim Sütunu' : 'First Name Column';
  String get mapLastName => isTurkish ? 'Soyisim Sütunu' : 'Last Name Column';
  String get mapPhone => isTurkish ? 'Telefon Numarası Sütunu' : 'Phone Number Column';
  String get mapDisplayName => isTurkish ? 'Görünen İsim Sütunu (Opsiyonel)' : 'Display Name Column (Optional)';
  String get selectColumn => isTurkish ? 'Sütun Seçin' : 'Select Column';
  String get ignoreColumn => isTurkish ? '— Kullanma —' : '— Do Not Use —';
  String get targetAccountTitle => isTurkish ? 'Hedef Depolama Hesabı' : 'Target Storage Account';
  String get skipExistingNumbers => isTurkish ? 'Varolan numaraları atla' : 'Skip existing phone numbers';
  String get skipExistingTooltip => isTurkish
      ? 'İşaretlenirse, rehberde zaten kayıtlı olan telefon numaraları tekrar eklenmez; ancak bu numaraya sahip kişilerin isim ve soyisim bilgileri yeni CSV verisiyle güncellenir.'
      : 'If checked, phone numbers already in your contacts will not be duplicated; however, existing contacts with these numbers will have their names updated.';
  String get startImport => isTurkish ? 'Rehbere İçe Aktar' : 'Import to Contacts';
  String get importingContacts => isTurkish ? 'Kişiler İçe Aktarılıyor...' : 'Importing Contacts...';
  String get importSuccessTitle => isTurkish ? 'İçe Aktarım Tamamlandı!' : 'Import Completed!';
  String importSummary(int added, int updated, int skipped) => isTurkish
      ? '$added yeni kişi eklendi, $updated varolan kişi güncellendi, $skipped kayıt atlandı.'
      : '$added new contact(s) added, $updated existing contact(s) updated, $skipped record(s) skipped.';
  String get invalidMappingError => isTurkish
      ? 'Lütfen en az Telefon Numarası ve bir İsim sütunu seçin.'
      : 'Please select at least Phone Number and one Name column.';

  // Import History & Rollback
  String get importHistory => isTurkish ? 'İçe Aktarım Geçmişi' : 'Import History';
  String get noHistoryFound => isTurkish ? 'Henüz bir içe aktarım geçmişi bulunmuyor.' : 'No import history found.';
  String get undoImport => isTurkish ? 'Geri Al' : 'Undo';
  String get undoConfirmTitle => isTurkish ? 'İçeri Aktarımı Geri Al' : 'Undo Import';
  String get undoConfirmMsg => isTurkish
      ? 'Bu içe aktarım işlemini geri almak istediğinizden emin misiniz? Eklenen kişiler rehberden silinecektir.'
      : 'Are you sure you want to undo this import? Newly added contacts will be deleted.';
  String get undoSuccess => isTurkish ? 'İçeri aktarım başarıyla geri alındı!' : 'Import successfully rolled back!';
  String get cancel => isTurkish ? 'İptal' : 'Cancel';

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
