import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/app_notification_service.dart';
import '../../services/key_repository.dart';
import '../all_keys/all_keys_screen.dart';
import '../event_log/event_log_screen.dart';
import '../register/register.dart';
import '../register/take_key_detail_screen.dart';
import '../register_new_key/register_new_key_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _now;
  late Timer _clockTimer;
  final TextEditingController _searchController = TextEditingController();
  final Stream<List<KeyRecord>> _keysInUseStream =
      KeyRecordRepository.watchKeysInUse();

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNotificationService.start();
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchController.dispose();
    AppNotificationService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        title: const Text('Key Record'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return Row(
              children: [
                if (isWide) _NavigationRail(onSelected: _handleNavigation),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshHomeData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderSection(now: _now),
                          const SizedBox(height: 16),
                          _SearchBar(
                            controller: _searchController,
                            onSubmitted: (value) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SearchScreen(
                                    initialQuery: value.trim(),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (!isWide) ...[
                            const SizedBox(height: 16),
                            _NavigationGrid(onSelected: _handleNavigation),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Keys Currently In Use',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Live list for keys collection where status is "in Use".',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<KeyRecord>>(
                            stream: _keysInUseStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final keys = snapshot.data ?? const [];
                              final borrowerGroups = _groupKeysByBorrower(keys);

                              if (borrowerGroups.isEmpty) {
                                return const _EmptyKeysState();
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: borrowerGroups.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return KeyInUseCard(
                                    group: borrowerGroups[index],
                                    onDetail: (record) => _openTakeKeyDetail(context, record),
                                    onReturn: (record) => _returnKey(context, record),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleNavigation(String label) {
    if (label == 'Take a Key') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
      );
      return;
    }

    if (label == 'Register New Key') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RegisterNewKeyScreen()),
      );
      return;
    }

    if (label == 'All Keys') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AllKeysScreen()),
      );
      return;
    }

    if (label == 'Event Log') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const EventLogScreen()),
      );
      return;
    }

    _showComingSoon(context, label);
  }

  void _openTakeKeyDetail(BuildContext context, KeyRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TakeKeyDetailScreen(record: record)),
    );
  }

  Future<void> _returnKey(BuildContext context, KeyRecord record) async {
    await KeyRecordRepository.returnKey(record);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${record.keyName} is now available.')),
    );
  }

  Future<void> _refreshHomeData() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final connected = await KeyRecordRepository.refreshAllFromFirestore();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            connected
                ? 'refreshing complete, have a nice day !'
                : 'Firebase not connected. Showing local data.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Refresh failed: $error')),
      );
    }
  }

  List<BorrowerKeyGroup> _groupKeysByBorrower(List<KeyRecord> keys) {
    final groups = <String, List<KeyRecord>>{};
    for (final key in keys) {
      final borrower = _borrowerLabel(key);
      final category = key.metadata['borrowerCategory']?.toString().trim() ?? '';
      final groupKey = '$borrower|$category';
      groups.putIfAbsent(groupKey, () => <KeyRecord>[]).add(key);
    }

    return groups.entries.map((entry) {
      final sample = entry.value.first;
      return BorrowerKeyGroup(
        borrowerName: _borrowerLabel(sample),
        borrowerCategory: sample.metadata['borrowerCategory']?.toString().trim() ?? '',
        keys: entry.value,
      );
    }).toList();
  }

  String _borrowerLabel(KeyRecord key) {
    final staffName = key.metadata['staffName']?.toString().trim() ?? '';
    final othersName = key.metadata['othersName']?.toString().trim() ?? '';
    if (staffName.isNotEmpty) {
      return staffName;
    }
    if (othersName.isNotEmpty) {
      return othersName;
    }
    if (key.borrowerName.trim().isNotEmpty) {
      return key.borrowerName;
    }
    return 'Unknown';
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label view is ready to connect next.')),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _HeaderValue(
            icon: Icons.person_outline,
            label: 'Logged-in user',
            value: AuthService.activeUser.isEmpty ? 'Security Admin' : AuthService.activeUser,
          ),
          _HeaderValue(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _formatDate(now),
          ),
          _HeaderValue(
            icon: Icons.schedule,
            label: 'Time',
            value: _formatTime(now),
          ),
        ],
      ),
    );
  }
}

class _HeaderValue extends StatelessWidget {
  const _HeaderValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE8F3F1),
          foregroundColor: const Color(0xFF00695C),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Search e.g. L8/190, SRV-ROOM-01, 0123456789, Zone-23B',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Open search',
          onPressed: () => onSubmitted(controller.text),
          icon: const Icon(Icons.arrow_forward),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
        ),
      ),
    );
  }
}

class _NavigationGrid extends StatelessWidget {
  const _NavigationGrid({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 620 ? 4 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _navigationItems.map((item) {
        return OutlinedButton.icon(
          onPressed: () => onSelected(item.label),
          icon: Icon(item.icon, size: 20),
          label: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF263238),
            side: const BorderSide(color: Color(0xFFD3DBDF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in _navigationItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: () => onSelected(item.label),
                icon: Icon(item.icon),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.label),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF263238),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class KeyInUseCard extends StatelessWidget {
  const KeyInUseCard({
    required this.group,
    required this.onDetail,
    required this.onReturn,
    super.key,
  });

  final BorrowerKeyGroup group;
  final ValueChanged<KeyRecord> onDetail;
  final ValueChanged<KeyRecord> onReturn;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: const Color(0x14000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD8E0E4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D5B4A), Color(0xFF1B8A70)],
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Borrower: ${group.borrowerName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (group.borrowerCategory.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3F1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            group.borrowerCategory,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF0D5B4A),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const _StatusTag(),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: group.keys.map((record) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFCFEFF), Color(0xFFF2F7FB)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCE6EE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFD7ECFF), Color(0xFFEAF5FF)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'KEY CATEGORY',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF385B7A),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.category,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF0D47A1),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4FA1E8), Color(0xFF8BC7FF), Color(0xFF4FA1E8)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      Text(
                        _keyDisplayLabel(record),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTakenDateTime(record.takenAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton(
                            onPressed: () => onReturn(record),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Return'),
                          ),
                          OutlinedButton(
                            onPressed: () => onDetail(record),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Detail'),
                          ),
                        ],
                      ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _keyDisplayLabel(KeyRecord record) {
    final level = record.metadata['level']?.toString().trim() ?? '';
    final zone = record.metadata['zone']?.toString().trim() ?? record.zone;
    final masterKey = record.metadata['masterKey']?.toString().trim() ?? '';
    final lot = record.metadata['lotKey']?.toString().trim() ?? '';
    final rollerLevelNo = record.metadata['rollerLevelNo']?.toString().trim() ?? '';
    final rollerNumber = record.metadata['rollerNumber']?.toString().trim() ?? '';

    if (record.category == 'Zone') {
      if (level.isNotEmpty && zone.isNotEmpty) {
        return '$level/$zone';
      }
      return zone;
    }

    if (record.category == 'Master Key') {
      if (masterKey.isNotEmpty) {
        return masterKey;
      }
      return record.keyName;
    }

    if (record.category == 'Lot') {
      if (level.isNotEmpty && lot.isNotEmpty) {
        return '$level/$lot';
      }
      if (lot.isNotEmpty) {
        return lot;
      }
      return record.keyName;
    }

    if (record.category == 'Roller Shutter') {
      if (rollerLevelNo.isNotEmpty && rollerNumber.isNotEmpty) {
        return '$rollerLevelNo / $rollerNumber';
      }
      if (rollerLevelNo.isNotEmpty) {
        return rollerLevelNo;
      }
      if (rollerNumber.isNotEmpty) {
        return rollerNumber;
      }
      return record.keyName;
    }

    return record.keyName;
  }

  String _formatTakenDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour${minute}HRS';
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF3B3B3)),
      ),
      child: const Text(
        'In Use',
        style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyKeysState extends StatelessWidget {
  const _EmptyKeysState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 44, color: Color(0xFF2E7D32)),
          SizedBox(height: 10),
          Text('No keys are currently in use.'),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const List<_NavigationItem> _navigationItems = [
  _NavigationItem('Take a Key', Icons.person_add_alt_1_outlined),
  _NavigationItem('Register New Key', Icons.add_card_outlined),
  _NavigationItem('Event Log', Icons.receipt_long_outlined),
  _NavigationItem('All Keys', Icons.list_alt_outlined),
];

class BorrowerKeyGroup {
  const BorrowerKeyGroup({
    required this.borrowerName,
    required this.borrowerCategory,
    required this.keys,
  });

  final String borrowerName;
  final String borrowerCategory;
  final List<KeyRecord> keys;
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day.toString().padLeft(2, '0')} '
      '${months[value.month - 1]} ${value.year}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}
