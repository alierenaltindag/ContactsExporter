enum AppMode {
  export,
  import,
}

class CsvColumnMapping {
  int? firstNameIndex;
  int? lastNameIndex;
  int? phoneIndex;
  int? displayNameIndex;

  CsvColumnMapping({
    this.firstNameIndex,
    this.lastNameIndex,
    this.phoneIndex,
    this.displayNameIndex,
  });

  /// Check if the mapping is valid (Phone number and at least one name field must be selected)
  bool get isValid =>
      phoneIndex != null &&
      (firstNameIndex != null || lastNameIndex != null || displayNameIndex != null);

  CsvColumnMapping copyWith({
    int? firstNameIndex,
    int? lastNameIndex,
    int? phoneIndex,
    int? displayNameIndex,
  }) {
    return CsvColumnMapping(
      firstNameIndex: firstNameIndex ?? this.firstNameIndex,
      lastNameIndex: lastNameIndex ?? this.lastNameIndex,
      phoneIndex: phoneIndex ?? this.phoneIndex,
      displayNameIndex: displayNameIndex ?? this.displayNameIndex,
    );
  }
}

class ImportHistoryRecord {
  final String id;
  final DateTime timestamp;
  final String fileName;
  final int totalRows;
  final int addedCount;
  final int updatedCount;
  final int skippedCount;
  final String targetAccountKey;
  final String targetAccountName;
  final bool isSkipExisting;
  final String backupFilePath;
  final List<String> createdContactIds;

  ImportHistoryRecord({
    required this.id,
    required this.timestamp,
    required this.fileName,
    required this.totalRows,
    required this.addedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.targetAccountKey,
    required this.targetAccountName,
    required this.isSkipExisting,
    required this.backupFilePath,
    required this.createdContactIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'fileName': fileName,
      'totalRows': totalRows,
      'addedCount': addedCount,
      'updatedCount': updatedCount,
      'skippedCount': skippedCount,
      'targetAccountKey': targetAccountKey,
      'targetAccountName': targetAccountName,
      'isSkipExisting': isSkipExisting,
      'backupFilePath': backupFilePath,
      'createdContactIds': createdContactIds,
    };
  }

  factory ImportHistoryRecord.fromJson(Map<String, dynamic> json) {
    return ImportHistoryRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fileName: json['fileName'] as String,
      totalRows: json['totalRows'] as int,
      addedCount: json['addedCount'] as int,
      updatedCount: json['updatedCount'] as int,
      skippedCount: json['skippedCount'] as int,
      targetAccountKey: json['targetAccountKey'] as String,
      targetAccountName: json['targetAccountName'] as String,
      isSkipExisting: json['isSkipExisting'] as bool,
      backupFilePath: json['backupFilePath'] as String,
      createdContactIds: List<String>.from(json['createdContactIds'] as List),
    );
  }
}
