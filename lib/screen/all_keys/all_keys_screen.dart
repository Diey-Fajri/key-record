import 'package:flutter/material.dart';

import '../../services/key_repository.dart';
import '../smart_detail/smart_detail_screen.dart';

class AllKeysScreen extends StatefulWidget {
  const AllKeysScreen({super.key});

  @override
  State<AllKeysScreen> createState() => _AllKeysScreenState();
}

class _AllKeysScreenState extends State<AllKeysScreen> {
  final _searchController = TextEditingController();
  String _selectedNavigation = 'All';
  String _selectedLevel = 'All';

  static const List<String> _navigationItems = [
    'All',
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

  static const List<String> _levelOptions = [
    'All',
    'B2',
    'B1',
    'L1',
    'L2',
    'L3',
    'L4',
    'L5',
    'L6',
    'L7',
    'L8',
    'L9',
    'L10',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('All Keys'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by status',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(_searchController.clear);
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _navigationItems.map((item) {
                  final selected = item == _selectedNavigation;
                  return FilterChip(
                    selected: selected,
                    label: Text(item),
                    onSelected: (_) {
                      setState(() {
                        _selectedNavigation = item;
                        if (item != 'Zone' && item != 'Lot' && item != 'Roller Shutter') {
                          _selectedLevel = 'All';
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            if (_selectedNavigation == 'Zone' ||
                _selectedNavigation == 'Lot' ||
                _selectedNavigation == 'Roller Shutter')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: InputDecoration(
                    labelText: 'Level',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    return const Center(child: Text('No key records available.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: keys.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = keys[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE0E5E8)),
                        ),
                        child: ListTile(
                          title: Text(_tileTitle(record)),
                          subtitle: Text(_tileSubtitle(record)),
                          trailing: _StatusTag(status: record.status),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SmartDetailScreen(record: record),
                              ),
                            );
                          },
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
    final query = _searchController.text.trim().toLowerCase();
    final filtered = keys.where((record) {
      final statusMatches = query.isEmpty || record.status.toLowerCase().contains(query);
      final navigationMatches = _matchesNavigation(record);
      return statusMatches && navigationMatches;
    }).toList();

    filtered.sort(_compareRecords);
    return filtered;
  }

  bool _matchesNavigation(KeyRecord record) {
    if (_selectedNavigation == 'All') {
      return true;
    }

    if (_selectedNavigation == 'Lost' ||
        _selectedNavigation == 'Hand Over' ||
        _selectedNavigation == 'Damaged' ||
        _selectedNavigation == 'Replaced') {
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

  int _compareRecords(KeyRecord a, KeyRecord b) {
    final first = _sortKey(a);
    final second = _sortKey(b);
    return first.compareTo(second);
  }

  String _sortKey(KeyRecord record) {
    if (_selectedNavigation == 'Zone') {
      return '${record.zone} ${record.keyName}'.toLowerCase();
    }
    if (_selectedNavigation == 'Master Key') {
      return record.keyName.toLowerCase();
    }
    if (_selectedNavigation == 'High Risk') {
      return record.keyName.toLowerCase();
    }
    if (_selectedNavigation == 'Lot') {
      return record.zone.toLowerCase();
    }
    if (_selectedNavigation == 'Roller Shutter') {
      final rollerNo = record.metadata['rollerNumber']?.toString() ?? '';
      return '${record.zone} $rollerNo'.toLowerCase();
    }
    if (_selectedNavigation == 'Lost' ||
        _selectedNavigation == 'Hand Over' ||
        _selectedNavigation == 'Damaged' ||
        _selectedNavigation == 'Replaced') {
      return record.keyName.toLowerCase();
    }
    return '${record.category} ${record.zone} ${record.keyName}'.toLowerCase();
  }

  String _tileTitle(KeyRecord record) {
    if (record.category == 'Zone' && _selectedNavigation == 'Zone') {
      return '${record.zone} ${record.keyName}';
    }

    if (record.category == 'Master Key') {
      return record.keyName;
    }

    if (record.category == 'Roller Shutter') {
      final rollerNumber = record.metadata['rollerNumber']?.toString();
      if (rollerNumber != null && rollerNumber.trim().isNotEmpty) {
        return '${record.zone} / $rollerNumber';
      }
    }

    return record.keyName.isNotEmpty ? record.keyName : record.zone;
  }

  String _tileSubtitle(KeyRecord record) {
    final parts = <String>[];
    if (record.zone.isNotEmpty) {
      parts.add(record.zone);
    }
    if (record.keyId.isNotEmpty) {
      parts.add(record.keyId);
    }
    if (record.category.isNotEmpty) {
      parts.add(record.category);
    }
    return parts.join(' • ');
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Available'
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
