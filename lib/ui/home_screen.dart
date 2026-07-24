import 'dart:io';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContactService _contactService = ContactService();
  final TextEditingController _searchController = TextEditingController();

  AppLanguage _currentLanguage = AppLanguage.en;
  AppTranslations get t => AppTranslations(_currentLanguage);

  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;

  List<ExportableContact> _allContacts = [];
  List<ExportableContact> _filteredContacts = [];
  List<ContactAccountSource> _accountSources = [];

  FilterOptions _filterOptions = const FilterOptions();

  // Export State
  bool _isExporting = false;
  File? _lastExportedFile;

  @override
  void initState() {
    super.initState();
    _detectInitialLanguage();
    _checkPermissionAndFetch();
  }

  void _detectInitialLanguage() {
    try {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final langCode = systemLocale.languageCode.toLowerCase();
      if (langCode.startsWith('tr')) {
        _currentLanguage = AppLanguage.tr;
      } else {
        _currentLanguage = AppLanguage.en;
      }
    } catch (_) {
      _currentLanguage = AppLanguage.en;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == AppLanguage.en
          ? AppLanguage.tr
          : AppLanguage.en;
    });
  }

  Future<void> _checkPermissionAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasPerm = await _contactService.hasPermission();
      setState(() {
        _hasPermission = hasPerm;
      });

      if (hasPerm) {
        await _loadContacts();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _contactService.requestPermission();
    setState(() {
      _hasPermission = granted;
    });
    if (granted) {
      await _loadContacts();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.permissionDeniedMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await _contactService.fetchAllContacts();
      final sources = _contactService.getAccountSources(contacts);

      setState(() {
        _allContacts = contacts;
        _accountSources = sources;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = '${t.errorOccurred}: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final filtered = _contactService.filterContacts(
      contacts: _allContacts,
      options: _filterOptions,
    );
    setState(() {
      _filteredContacts = filtered;
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _filterOptions = _filterOptions.copyWith(query: query);
    });
    _applyFilters();
  }

  void _updateMatchType(SearchMatchType matchType) {
    setState(() {
      _filterOptions = _filterOptions.copyWith(matchType: matchType);
    });
    _applyFilters();
  }

  void _updateSelectedAccount(String accountKey) {
    setState(() {
      _filterOptions = _filterOptions.copyWith(selectedAccountKey: accountKey);
    });
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filterOptions = _filterOptions.copyWith(query: '');
    });
    _applyFilters();
  }

  Future<void> _exportCsv() async {
    if (_filteredContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.noMatchesToExport),
          backgroundColor: AppTheme.accentAmber,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final file = await _contactService.generateCsvFile(_filteredContacts);
      setState(() {
        _lastExportedFile = file;
        _isExporting = false;
      });

      if (mounted) {
        _showExportSuccessBottomSheet(file);
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.errorOccurred}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _shareCsvFile(File file) async {
    try {
      await _contactService.shareCsvFile(
        file,
        contactCount: _filteredContacts.length,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.errorOccurred}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showExportSuccessBottomSheet(File file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.secondary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.exportSuccess,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.exportedCountMsg(_filteredContacts.length),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined,
                        color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        file.path.split('/').last,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: Text(t.close),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.borderDark),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _shareCsvFile(file);
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: Text(t.shareCsvFile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.appTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  t.appSubtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Switcher Button
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    Text(_currentLanguage.flag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      _currentLanguage.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _checkPermissionAndFetch,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: t.rescanTooltip,
          ),
        ],
      ),
      body: !_hasPermission
          ? _buildPermissionView()
          : _isLoading
              ? _buildLoadingView()
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildMainView(),
      bottomNavigationBar: _hasPermission && !_isLoading && _errorMessage == null
          ? _buildBottomActionBar()
          : null,
    );
  }

  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_phone_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.permissionTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.permissionDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.security_rounded),
                label: Text(t.grantAccess),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            t.scanningContacts,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? t.errorOccurred,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkPermissionAndFetch,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    final totalCount = _allContacts.length;
    final filteredCount = _filteredContacts.length;

    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Stats Header Card
                  _buildStatsHeaderCard(totalCount, filteredCount),
                  const SizedBox(height: 16),

                  // Storage Account Select Menu Dropdown
                  _buildAccountSelectMenu(),
                  const SizedBox(height: 16),

                  // Text Search & Match Mode Filter Section
                  _buildSearchFilterSection(),
                  const SizedBox(height: 16),

                  // Contacts Preview Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.matchedContacts(filteredCount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (_filterOptions.query.isNotEmpty ||
                          _filterOptions.selectedAccountKey != 'ALL')
                        TextButton.icon(
                          onPressed: () {
                            _clearSearch();
                            _updateSelectedAccount('ALL');
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: Text(
                            t.resetFilters,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.accentCyan,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Contact Items Preview List
          _filteredContacts.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final contact = _filteredContacts[index];
                      return _buildContactTile(contact);
                    },
                    childCount: _filteredContacts.length,
                  ),
                ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeaderCard(int totalCount, int filteredCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceDark,
            AppTheme.surfaceDark.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.totalContacts,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.borderDark,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.filteredResult,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$filteredCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.sourcesCount(_accountSources.length),
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Modern Select Menu / Dropdown for Storage Source Selection
  Widget _buildAccountSelectMenu() {
    final selectedKey = _filterOptions.selectedAccountKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storage_rounded, size: 16, color: AppTheme.accentCyan),
            const SizedBox(width: 6),
            Text(
              t.storageSourceLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selectedKey != 'ALL'
                  ? AppTheme.primary
                  : AppTheme.borderDark,
              width: selectedKey != 'ALL' ? 1.5 : 1.0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedKey,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceDark,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
              borderRadius: BorderRadius.circular(14),
              items: [
                // All Sources Option
                DropdownMenuItem<String>(
                  value: 'ALL',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.all_inbox_rounded, size: 18, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.allSources(_allContacts.length),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scanned Account Sources (Count > 0)
                ..._accountSources.map((source) {
                  return DropdownMenuItem<String>(
                    value: source.key,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _getAccountIcon(source.rawType),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            source.displayName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${source.count}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                if (val != null) {
                  _updateSelectedAccount(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _getAccountIcon(String rawType) {
    final lower = rawType.toLowerCase();
    if (lower.contains('google')) {
      return const Icon(Icons.g_mobiledata_rounded,
          size: 20, color: Colors.redAccent);
    } else if (lower.contains('sim')) {
      return const Icon(Icons.sim_card_rounded,
          size: 16, color: AppTheme.accentAmber);
    } else if (lower.contains('icloud')) {
      return const Icon(Icons.cloud_rounded,
          size: 16, color: AppTheme.accentCyan);
    }
    return const Icon(Icons.phone_android_rounded,
        size: 16, color: AppTheme.textMuted);
  }

  Widget _buildSearchFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Input
        TextField(
          controller: _searchController,
          onChanged: _updateSearchQuery,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: t.searchHint,
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded,
                        color: AppTheme.textMuted),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Match Mode Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SearchMatchType.values.map((mode) {
              final isSelected = _filterOptions.matchType == mode;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(mode.getLabel(t)),
                  selected: isSelected,
                  onSelected: (_) => _updateMatchType(mode),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                  checkmarkColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.borderDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile(ExportableContact contact) {
    final initials = contact.displayName.isNotEmpty
        ? contact.displayName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark, width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
          foregroundColor: AppTheme.primary,
          radius: 20,
          child: Text(
            initials,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Text(
          contact.displayName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.phone_rounded,
                    size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  contact.phoneNumber.isNotEmpty
                      ? contact.phoneNumber
                      : t.noPhone,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Text(
                contact.accountName,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            t.noContactsFound,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.emptyStateSub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _clearSearch();
              _updateSelectedAccount('ALL');
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(t.resetFilters),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final count = _filteredContacts.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportCsv,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_isExporting
                    ? t.exportingCsv
                    : t.exportCsv(count)),
              ),
            ),
            if (_lastExportedFile != null) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _shareCsvFile(_lastExportedFile!),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(t.shareCsv),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
