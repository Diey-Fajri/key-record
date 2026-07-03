import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/key_repository.dart';
import '../all_keys/all_keys_screen.dart';
import '../event_log/event_log_screen.dart';
import '../no_return/no_return_screen.dart';
import '../register/register.dart';
import '../register_new_key/register_new_key_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../smart_detail/smart_detail_screen.dart';

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
            onPressed: () => _handleNavigation('Settings'),
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
                  child: SingleChildScrollView(
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

                            if (keys.isEmpty) {
                              return const _EmptyKeysState();
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: keys.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return KeyInUseCard(
                                  record: keys[index],
                                  onDetail: () =>
                                      _openSmartDetail(context, keys[index]),
                                );
                              },
                            );
                          },
                        ),
                      ],
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

    if (label == 'No Return / Lost / At Maintenance') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NoReturnScreen()),
      );
      return;
    }

    if (label == 'Settings') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );
      return;
    }

    _showComingSoon(context, label);
  }

  void _openSmartDetail(BuildContext context, KeyRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SmartDetailScreen(record: record)),
    );
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
        hintText: 'Search key, borrower, company, or zone',
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
  const KeyInUseCard({required this.record, required this.onDetail, super.key});

  final KeyRecord record;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E5E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final keyInfo = Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F3F1),
                  foregroundColor: const Color(0xFF00695C),
                  child: const Icon(Icons.vpn_key_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.keyName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.zone,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _StatusTag(),
                FilledButton.icon(
                  key: ValueKey('smart-detail-${record.keyName}'),
                  onPressed: onDetail,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Smart Detail'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [keyInfo, const SizedBox(height: 12), actions],
              );
            }

            return Row(
              children: [
                Expanded(child: keyInfo),
                const SizedBox(width: 12),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB7B7)),
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
  _NavigationItem('No Return / Lost / At Maintenance', Icons.warning_amber),
  _NavigationItem('Settings', Icons.settings_outlined),
];

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
