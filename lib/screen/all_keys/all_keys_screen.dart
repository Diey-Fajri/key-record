import 'package:flutter/material.dart';

import '../../services/key_repository.dart';
import '../smart_detail/smart_detail_screen.dart';

String _displayLevelLabel(String level) {
  if (level == 'B2' || level == 'B1') {
    return 'Level $level';
  }
  return level;
}

class AllKeysScreen extends StatefulWidget {
  const AllKeysScreen({super.key});

  @override
  State<AllKeysScreen> createState() => _AllKeysScreenState();
}

class _AllKeysScreenState extends State<AllKeysScreen> {
  String _selectedNavigation = 'All';
  String _selectedLevel = 'All';

  static const List<String> _navigationItems = [
    'All',
    'Available',
    'In Use',
    'No Return',
    'At Maintenance',
    'Zone',
    'Master Key',
    'High Risk',
    'Lot',
    'Roller Shutter',
    'Lost',
    'Not Available',
    'Hand Over',
    'Damaged',
    'Replaced',
    'Others',
  ];

  static const List<String> _statusNavigationItems = [
    'Available',
    'In Use',
    'No Return',
    'At Maintenance',
    'Lost',
    'Not Available',
    'Hand Over',
    'Damaged',
    'Replaced',
  ];

  static final List<String> _levelOptions = [
    'All',
    'B2',
    'B1',
    for (var i = 1; i <= 40; i++) 'L$i',
  ];

  bool get _navigationUsesLevel {
    return _selectedNavigation == 'All' ||
        _selectedNavigation == 'Zone' ||
        _selectedNavigation == 'Lot' ||
        _selectedNavigation == 'Roller Shutter';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        title: const Text('All Keys'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<List<KeyRecord>>(
          stream: KeyRecordRepository.watchAllKeys(),
          builder: (context, snapshot) {
            final allKeys = snapshot.data ?? const <KeyRecord>[];
            final stats = _buildStatistics(allKeys);
            final keys = _filteredKeys(allKeys);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F2A30), Color(0xFF2F4550)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Navigation',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a category button, then filter by level.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _navigationItems.map((item) {
                      final selected = item == _selectedNavigation;
                      return FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectedNavigation = item;
                            _selectedLevel = 'All';
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: selected
                              ? const Color(0xFF263238)
                              : Colors.white,
                          foregroundColor: selected
                              ? Colors.white
                              : const Color(0xFF263238),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF263238)
                                : const Color(0xFFCFD8DC),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                        child: Text(item),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E5E8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Total',
                            value: stats['total'] ?? 0,
                            accentColor: const Color(0xFF1E3A5F),
                          ),
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFFE4E9EE)),
                        Expanded(
                          child: _StatTile(
                            label: 'In Use',
                            value: stats['inUse'] ?? 0,
                            accentColor: const Color(0xFF00695C),
                          ),
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFFE4E9EE)),
                        Expanded(
                          child: _StatTile(
                            label: 'Available',
                            value: stats['available'] ?? 0,
                            accentColor: const Color(0xFF2E7D32),
                          ),
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFFE4E9EE)),
                        Expanded(
                          child: _StatTile(
                            label: 'Not Available',
                            value: stats['notAvailable'] ?? 0,
                            accentColor: const Color(0xFFEF6C00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_navigationUsesLevel) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Level',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedLevel,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.stairs_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _levelOptions
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(_displayLevelLabel(level)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLevel = value);
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: () {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        keys.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (keys.isEmpty) {
                      return const Center(
                        child: Text('No key records for this selection.'),
                      );
                    }

                    final grouped = _groupByLevel(keys);
                    final levelSections = _selectedLevel == 'All'
                        ? grouped.entries.toList()
                        : grouped.entries
                              .where((entry) => entry.key == _selectedLevel)
                              .toList();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: levelSections.length,
                      itemBuilder: (context, index) {
                        final section = levelSections[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _LevelSection(
                            levelLabel: section.key,
                            records: section.value,
                          ),
                        );
                      },
                    );
                  }(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<KeyRecord> _filteredKeys(List<KeyRecord> keys) {
    final filtered = keys.where((record) {
      final navigationMatches = _matchesNavigation(record);
      final levelMatches =
          !_navigationUsesLevel ||
          _selectedLevel == 'All' ||
          _recordLevel(record) == _selectedLevel;
      return navigationMatches && levelMatches;
    }).toList();

    filtered.sort(_compareRecords);
    return filtered;
  }

  bool _matchesNavigation(KeyRecord record) {
    if (_selectedNavigation == 'All') {
      return true;
    }

    if (_statusNavigationItems.contains(_selectedNavigation)) {
      return record.status == _selectedNavigation;
    }

    if (_selectedNavigation == 'Others') {
      return record.category == 'Others';
    }

    if (_selectedNavigation == 'High Risk') {
      return record.category == 'High Risk' || record.status == 'High Risk';
    }

    if (_selectedNavigation == 'Zone') {
      return record.category == 'Zone';
    }

    if (_selectedNavigation == 'Master Key') {
      return record.category == 'Master Key';
    }

    if (_selectedNavigation == 'Lot') {
      return record.category == 'Lot';
    }

    if (_selectedNavigation == 'Roller Shutter') {
      return record.category == 'Roller Shutter';
    }

    return true;
  }

  Map<String, int> _buildStatistics(List<KeyRecord> keys) {
    return {
      'total': keys.length,
      'inUse': keys.where((record) => record.status == 'In Use').length,
      'available': keys.where((record) => record.status == 'Available').length,
      'notAvailable': keys.where((record) => record.status == 'Not Available').length,
    };
  }

  Map<String, List<KeyRecord>> _groupByLevel(List<KeyRecord> keys) {
    final map = <String, List<KeyRecord>>{};
    for (final level in _levelOptions) {
      if (level != 'All') {
        map[level] = <KeyRecord>[];
      }
    }
    map['Other'] = <KeyRecord>[];

    for (final record in keys) {
      final level = _recordLevel(record);
      if (map.containsKey(level)) {
        map[level]!.add(record);
      } else {
        map['Other']!.add(record);
      }
    }

    map.removeWhere((_, value) => value.isEmpty);
    return map;
  }

  int _compareRecords(KeyRecord a, KeyRecord b) {
    final topA = _topKeyLabel(a, _selectedNavigation).toUpperCase();
    final topB = _topKeyLabel(b, _selectedNavigation).toUpperCase();
    final byTop = _naturalCompare(topA, topB);
    if (byTop != 0) return byTop;

    // If top labels are equal (same folder), compare keyId naturally,
    // fall back to keyName if keyId is not decisive.
    final byKeyId = _naturalCompare(a.keyId.toUpperCase(), b.keyId.toUpperCase());
    if (byKeyId != 0) return byKeyId;
    return _naturalCompare(a.keyName.toUpperCase(), b.keyName.toUpperCase());
  }

  String _sortKey(KeyRecord record) {
    return '${_topKeyLabel(record, _selectedNavigation)} ${record.keyId}'
        .toLowerCase();
  }

  int _naturalCompare(String a, String b) {
    final partsA = _splitNaturalParts(a);
    final partsB = _splitNaturalParts(b);
    final minLength = partsA.length < partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < minLength; i++) {
      final left = partsA[i];
      final right = partsB[i];

      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      if (leftNumber != null && rightNumber != null) {
        final numberCompare = leftNumber.compareTo(rightNumber);
        if (numberCompare != 0) {
          return numberCompare;
        }
        continue;
      }

      final textCompare = left.toUpperCase().compareTo(right.toUpperCase());
      if (textCompare != 0) {
        return textCompare;
      }
    }

    return partsA.length.compareTo(partsB.length);
  }

  List<String> _splitNaturalParts(String input) {
    final matches = RegExp(r'\d+|[A-Za-z]+').allMatches(input);
    if (matches.isEmpty) {
      final fallback = input.trim();
      return fallback.isEmpty ? const <String>[] : <String>[fallback];
    }
    return matches.map((match) => match.group(0) ?? '').toList(growable: false);
  }

  String _recordLevel(KeyRecord record) {
    final metadataLevel = record.metadata['level']?.toString() ?? '';
    final normalizedMetadata = _normalizeLevel(metadataLevel);
    if (normalizedMetadata.isNotEmpty) {
      return normalizedMetadata;
    }

    final rollerLevelNo = record.metadata['rollerLevelNo']?.toString() ?? '';
    final normalizedRoller = _normalizeLevel(rollerLevelNo);
    if (normalizedRoller.isNotEmpty) {
      return normalizedRoller;
    }

    final zone = record.zone.toUpperCase();
    final match = RegExp(r'\b(B2|B1|L\d{1,2})\b').firstMatch(zone);
    if (match != null) {
      return match.group(0)!;
    }
    return 'Other';
  }

  String _normalizeLevel(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper.isEmpty) {
      return '';
    }

    final bMatch = RegExp(r'\bB[12]\b').firstMatch(upper);
    if (bMatch != null) {
      return bMatch.group(0)!;
    }

    final levelMatch = RegExp(r'\b(?:LEVEL\s*)?(\d{1,2})\b').firstMatch(upper);
    if (levelMatch != null) {
      return 'L${levelMatch.group(1)}';
    }

    final lMatch = RegExp(r'\bL(\d{1,2})\b').firstMatch(upper);
    if (lMatch != null) {
      return 'L${lMatch.group(1)}';
    }

    return '';
  }

  String _topKeyLabel(KeyRecord record, String selectedNavigation) {
    final level = _recordLevel(record);
    final zoneField = record.metadata['zone']?.toString().trim() ?? '';
    final masterField = record.metadata['masterKey']?.toString().trim() ?? '';
    final lotField = record.metadata['lotKey']?.toString().trim() ?? '';
    final rollerField =
        record.metadata['rollerNumber']?.toString().trim() ?? '';
    final category = record.category;
    final effectiveCategory =
        selectedNavigation == 'All' ||
            selectedNavigation == 'High Risk' ||
            selectedNavigation == 'Lost' ||
            selectedNavigation == 'Hand Over' ||
            selectedNavigation == 'Damaged' ||
            selectedNavigation == 'Replaced'
        ? category
        : selectedNavigation;

    if (effectiveCategory == 'Zone') {
      final zoneValue = zoneField.isNotEmpty ? zoneField : record.zone;
      return _combineLevelAndValue(level, zoneValue);
    }

    if (effectiveCategory == 'Roller Shutter') {
      final rollerNo = rollerField.isNotEmpty
          ? rollerField
          : (record.metadata['rollerLevelNo']?.toString().trim() ??
                record.keyName);
      return _combineLevelAndValue(level, rollerNo);
    }

    if (effectiveCategory == 'Master Key') {
      return masterField.isNotEmpty ? masterField : record.keyName;
    }

    if (effectiveCategory == 'Lot') {
      final lotNo = lotField.isNotEmpty ? lotField : record.keyName;
      return _combineLevelAndValue(level, lotNo);
    }

    if (effectiveCategory == 'Others') {
      return record.keyName;
    }

    return record.keyName;
  }

  String _combineLevelAndValue(String level, String value) {
    final cleanLevel = level == 'Other' ? '' : level;
    final cleanValue = value.trim();
    if (cleanLevel.isNotEmpty && cleanValue.isNotEmpty) {
      return '$cleanLevel / $cleanValue';
    }
    if (cleanValue.isNotEmpty) {
      return cleanValue;
    }
    return cleanLevel.isNotEmpty ? cleanLevel : 'Unnamed Key';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final int value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF607D8B),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              '$value',
              key: ValueKey('$label-$value'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({required this.levelLabel, required this.records});

  final String levelLabel;
  final List<KeyRecord> records;

  @override
  Widget build(BuildContext context) {
    final groupedRecords = _folderGroups();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE3E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _displayLevelLabel(levelLabel),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1F8),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${records.length} keys',
                  style: const TextStyle(
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...groupedRecords.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FolderGroupCard(label: entry.key, records: entry.value),
            );
          }),
        ],
      ),
    );
  }

  Map<String, List<KeyRecord>> _folderGroups() {
    final grouped = <String, List<KeyRecord>>{};

    for (final record in records) {
      final groupLabel = _folderLabelForRecord(record);
      grouped.putIfAbsent(groupLabel, () => <KeyRecord>[]).add(record);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => _folderOrder(a.key).compareTo(_folderOrder(b.key)));

    return {for (final entry in sortedEntries) entry.key: entry.value};
  }

  String _folderLabelForRecord(KeyRecord record) {
    if (record.category == 'Zone') {
      return _zoneFolderLabel(record);
    }

    if (record.category == 'Roller Shutter') {
      return levelLabel == 'Other'
          ? 'Roller Shutter'
          : 'Roller Shutter (${_displayLevelLabel(levelLabel)})';
    }

    return record.category;
  }

  String _zoneFolderLabel(KeyRecord record) {
    final zoneRaw =
        (record.metadata['zone']?.toString().trim().isNotEmpty ?? false)
        ? record.metadata['zone'].toString().trim()
        : record.zone.trim();
    final upper = zoneRaw.toUpperCase();
    final trailingAlpha = RegExp(r'([A-Z]+)$').firstMatch(upper)?.group(1);
    if (trailingAlpha != null && trailingAlpha.isNotEmpty) {
      return 'Zone $trailingAlpha';
    }

    if (upper.isNotEmpty) {
      return 'Zone $upper';
    }

    return 'Zone Other';
  }

  int _folderOrder(String label) {
    if (label.startsWith('Zone ')) {
      return 0;
    }
    if (label.startsWith('Roller Shutter')) {
      return 1;
    }
    if (label == 'Master Key') {
      return 2;
    }
    if (label == 'Lot') {
      return 3;
    }
    if (label == 'Others') {
      return 4;
    }
    return 5;
  }
}

class _FolderGroupCard extends StatelessWidget {
  const _FolderGroupCard({required this.label, required this.records});

  final String label;
  final List<KeyRecord> records;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE3E7)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        leading: const Icon(Icons.folder_outlined, color: Color(0xFF1E3A5F)),
        title: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1F8),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${records.length}',
            style: const TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        children: records
            .map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _KeyRecordCard(record: record),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _KeyRecordCard extends StatelessWidget {
  const _KeyRecordCard({required this.record});

  final KeyRecord record;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = _primaryLabel(record);
    final secondaryLabel = _secondaryLabel(record);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SmartDetailScreen(record: record),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E5E8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (secondaryLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      secondaryLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
            _StatusChip(status: record.status),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFF607D8B)),
          ],
        ),
      ),
    );
  }

  String _topKeyLabel(KeyRecord record) {
    final level = _recordLevel(record);
    if (record.category == 'Zone') {
      final zoneValue = (record.metadata['zone']?.toString() ?? '').trim();
      return _combineLevelAndValue(
        level,
        zoneValue.isNotEmpty ? zoneValue : record.zone,
      );
    }

    if (record.category == 'Master Key') {
      final master = (record.metadata['masterKey']?.toString() ?? '').trim();
      final value = master.isNotEmpty ? master : record.keyName;
      return _combineLevelAndValue(level, value);
    }

    if (record.category == 'Lot') {
      final lotNo = (record.metadata['lotKey']?.toString() ?? '').trim();
      return _combineLevelAndValue(
        level,
        lotNo.isNotEmpty ? lotNo : record.keyName,
      );
    }

    if (record.category == 'Roller Shutter') {
      final rollerNo = (record.metadata['rollerNumber']?.toString() ?? '')
          .trim();
      final fallback = record.keyName.trim();
      return _combineLevelAndValue(
        level,
        rollerNo.isNotEmpty ? rollerNo : fallback,
      );
    }

    if (record.category == 'High Risk' || record.category == 'Others') {
      return _combineLevelAndValue(level, record.keyName);
    }

    return _combineLevelAndValue(level, record.keyName);
  }

  String _primaryLabel(KeyRecord record) {
    if (record.category == 'Roller Shutter') {
      return 'Roller Shutter';
    }
    return _topKeyLabel(record);
  }

  String _secondaryLabel(KeyRecord record) {
    if (record.category != 'Roller Shutter') {
      return '';
    }

    final level = _recordLevel(record);
    final rollerNo = (record.metadata['rollerNumber']?.toString() ?? '').trim();
    final fallback = record.keyName.trim();
    final number = rollerNo.isNotEmpty ? rollerNo : fallback;
    return _combineLevelAndValue(level, number);
  }

  String _recordLevel(KeyRecord record) {
    final metadataLevel = record.metadata['level']?.toString() ?? '';
    final normalizedMetadata = _normalizeLevel(metadataLevel);
    if (normalizedMetadata.isNotEmpty) {
      return normalizedMetadata;
    }

    final rollerLevelNo = record.metadata['rollerLevelNo']?.toString() ?? '';
    final normalizedRoller = _normalizeLevel(rollerLevelNo);
    if (normalizedRoller.isNotEmpty) {
      return normalizedRoller;
    }

    final zone = record.zone.toUpperCase();
    final match = RegExp(r'\b(B2|B1|L\d{1,2})\b').firstMatch(zone);
    if (match != null) {
      return match.group(0)!;
    }
    return 'Other';
  }

  String _normalizeLevel(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper.isEmpty) {
      return '';
    }

    final bMatch = RegExp(r'\bB[12]\b').firstMatch(upper);
    if (bMatch != null) {
      return bMatch.group(0)!;
    }

    final levelMatch = RegExp(r'\b(?:LEVEL\s*)?(\d{1,2})\b').firstMatch(upper);
    if (levelMatch != null) {
      return 'L${levelMatch.group(1)}';
    }

    final lMatch = RegExp(r'\bL(\d{1,2})\b').firstMatch(upper);
    if (lMatch != null) {
      return 'L${lMatch.group(1)}';
    }

    return '';
  }

  String _combineLevelAndValue(String level, String value) {
    final cleanLevel = level == 'Other' ? '' : level;
    final cleanValue = value.trim();
    if (cleanLevel.isNotEmpty && cleanValue.isNotEmpty) {
      return '$cleanLevel / $cleanValue';
    }
    if (cleanValue.isNotEmpty) {
      return cleanValue;
    }
    return cleanLevel.isNotEmpty ? cleanLevel : 'Unnamed Key';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = status == 'Available'
        ? const Color(0xFFE7F5EA)
        : status == 'In Use'
        ? const Color(0xFFE8F3F1)
        : status == 'Hand Over'
        ? const Color(0xFFE9EEF6)
        : status == 'Damaged' || status == 'Replaced'
        ? const Color(0xFFFFF3E0)
        : status == 'Not Available'
        ? const Color(0xFFFFF4E5)
        : const Color(0xFFFFE5E5);

    final textColor = status == 'Available'
        ? const Color(0xFF2E7D32)
        : status == 'In Use'
        ? const Color(0xFF00695C)
        : status == 'Hand Over'
        ? const Color(0xFF1E3A5F)
        : status == 'Damaged' || status == 'Replaced'
        ? const Color(0xFFEF6C00)
        : status == 'Not Available'
        ? const Color(0xFF8D6E63)
        : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
