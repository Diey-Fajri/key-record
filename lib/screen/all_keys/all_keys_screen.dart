import 'package:flutter/material.dart';

import '../../services/key_repository.dart';
import '../smart_detail/smart_detail_screen.dart';

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
    return _selectedNavigation != 'Master Key' && _selectedNavigation != 'Others';
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
        child: Column(
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
                      backgroundColor:
                          selected ? const Color(0xFF263238) : Colors.white,
                      foregroundColor:
                          selected ? Colors.white : const Color(0xFF263238),
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
                      .map((level) => DropdownMenuItem(value: level, child: Text(level)))
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
              child: StreamBuilder<List<KeyRecord>>(
                stream: KeyRecordRepository.watchAllKeys(),
                builder: (context, snapshot) {
                  final keys = _filteredKeys(snapshot.data ?? const []);
                  if (snapshot.connectionState == ConnectionState.waiting && keys.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (keys.isEmpty) {
                    return const Center(child: Text('No key records for this selection.'));
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
                          selectedNavigation: _selectedNavigation,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<KeyRecord> _filteredKeys(List<KeyRecord> keys) {
    final filtered = keys.where((record) {
      final navigationMatches = _matchesNavigation(record);
      final levelMatches = !_navigationUsesLevel || _selectedLevel == 'All' || _recordLevel(record) == _selectedLevel;
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
    final first = _sortKey(a);
    final second = _sortKey(b);
    return first.compareTo(second);
  }

  String _sortKey(KeyRecord record) {
    return '${_topKeyLabel(record, _selectedNavigation)} ${record.keyId}'.toLowerCase();
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
    final rollerField = record.metadata['rollerNumber']?.toString().trim() ?? '';
    final category = record.category;
    final effectiveCategory = selectedNavigation == 'All' ||
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
          : (record.metadata['rollerLevelNo']?.toString().trim() ?? record.keyName);
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

class _LevelSection extends StatelessWidget {
  const _LevelSection({
    required this.levelLabel,
    required this.records,
    required this.selectedNavigation,
  });

  final String levelLabel;
  final List<KeyRecord> records;
  final String selectedNavigation;

  @override
  Widget build(BuildContext context) {
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
                levelLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _KeyRecordCard(
                record: record,
                selectedNavigation: selectedNavigation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyRecordCard extends StatelessWidget {
  const _KeyRecordCard({
    required this.record,
    required this.selectedNavigation,
  });

  final KeyRecord record;
  final String selectedNavigation;

  bool get _showBorrowerDetails => record.status == 'In Use';

  @override
  Widget build(BuildContext context) {
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
                    _topKeyLabel(record),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.category} • ${record.keyName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  if (_showBorrowerDetails) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Taken by: ${_borrowerName(record)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (_companyDepartment(record).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _companyDepartment(record),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                    if (record.purpose.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Purpose: ${record.purpose.trim()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
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
    final category = record.category;
    final effectiveCategory = selectedNavigation == 'All' ||
            selectedNavigation == 'High Risk' ||
            selectedNavigation == 'Lost' ||
            selectedNavigation == 'Hand Over' ||
            selectedNavigation == 'Damaged' ||
            selectedNavigation == 'Replaced'
        ? category
        : selectedNavigation;

    if (effectiveCategory == 'Zone') {
      final zoneValue = (record.metadata['zone']?.toString() ?? '').trim();
      return _combineLevelAndValue(level, zoneValue.isNotEmpty ? zoneValue : record.zone);
    }

    if (effectiveCategory == 'Roller Shutter') {
      final rollerNo = (record.metadata['rollerNumber']?.toString() ?? '').trim();
      final fallback = (record.metadata['rollerLevelNo']?.toString() ?? record.keyName).trim();
      return _combineLevelAndValue(level, rollerNo.isNotEmpty ? rollerNo : fallback);
    }

    if (effectiveCategory == 'Master Key') {
      final master = (record.metadata['masterKey']?.toString() ?? '').trim();
      return master.isNotEmpty ? master : record.keyName;
    }

    if (effectiveCategory == 'Lot') {
      final lotNo = (record.metadata['lotKey']?.toString() ?? '').trim();
      return _combineLevelAndValue(level, lotNo.isNotEmpty ? lotNo : record.keyName);
    }

    if (effectiveCategory == 'Others') {
      return record.keyName.isNotEmpty ? record.keyName : 'Unnamed Key';
    }

    return record.keyName.isNotEmpty ? record.keyName : 'Unnamed Key';
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

  String _borrowerName(KeyRecord record) {
    final borrower = record.borrowerName.trim();
    return borrower.isEmpty ? 'member' : borrower;
  }

  String _companyDepartment(KeyRecord record) {
    final company = record.company.trim();
    final department = record.metadata['department']?.toString().trim() ?? '';

    if (company.isNotEmpty && department.isNotEmpty) {
      return 'Company / Department: $company / $department';
    }
    if (company.isNotEmpty) {
      return 'Company: $company';
    }
    if (department.isNotEmpty) {
      return 'Department: $department';
    }
    return '';
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
                    : const Color(0xFFFFE5E5);

    final textColor = status == 'Available'
        ? const Color(0xFF2E7D32)
        : status == 'In Use'
            ? const Color(0xFF00695C)
            : status == 'Hand Over'
                ? const Color(0xFF1E3A5F)
                : status == 'Damaged' || status == 'Replaced'
                    ? const Color(0xFFEF6C00)
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

