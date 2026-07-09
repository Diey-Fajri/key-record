import 'package:flutter/material.dart';

import '../../core/app_action_theme.dart';
import '../../services/key_repository.dart';
import '../../widget/beautiful_submit_button.dart';

enum NoReturnAction { lost, noReturn, maintenance }

class NoReturnScreen extends StatefulWidget {
  const NoReturnScreen({super.key});

  @override
  State<NoReturnScreen> createState() => _NoReturnScreenState();
}

class _NoReturnScreenState extends State<NoReturnScreen> {
  final _searchController = TextEditingController();
  final _staffController = TextEditingController();
  final _remarksController = TextEditingController();
  NoReturnAction? _selectedAction;
  final List<KeyRecord> _selectedKeys = [];
  bool _isSubmitting = false;

  String get _currentUserName => 'Admin User';

  bool get _requiresStaff {
    return _selectedAction == NoReturnAction.noReturn ||
        _selectedAction == NoReturnAction.maintenance;
  }

  String get _actionLabel {
    switch (_selectedAction) {
      case NoReturnAction.lost:
        return 'Lost';
      case NoReturnAction.noReturn:
        return 'No Return';
      case NoReturnAction.maintenance:
        return 'At Maintenance';
      default:
        return 'Select action';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staffController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('No Return / Lost / At Maintenance'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIntroCard(),
            const SizedBox(height: 16),
            _buildActionSelector(),
            if (_selectedAction != null) ...[
              const SizedBox(height: 16),
              _buildFormCard(),
            ],
            const SizedBox(height: 16),
            _buildLockedKeysSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Action selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Choose whether the key is being marked as Lost, No Return, or At Maintenance.'),
          SizedBox(height: 8),
          Text('Once submitted, the key status is locked and only an admin can restore it.'),
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<NoReturnAction>(
          initialValue: _selectedAction,
          decoration: _inputDecoration('Choose action', Icons.warning_amber_outlined),
          items: const [
            DropdownMenuItem(value: NoReturnAction.lost, child: Text('Lost')),
            DropdownMenuItem(value: NoReturnAction.noReturn, child: Text('No Return (HR/Staff)')),
            DropdownMenuItem(value: NoReturnAction.maintenance, child: Text('At Maintenance')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAction = value;
              _selectedKeys.clear();
              _searchController.clear();
              _staffController.clear();
              _remarksController.clear();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_actionLabel form', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildReadOnlyField('Name', _currentUserName, Icons.person_outline),
            const SizedBox(height: 14),
            _buildSearchSection(),
            if (_requiresStaff) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _staffController,
                decoration: _inputDecoration('Staff Name', Icons.badge_outlined),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: _inputDecoration('Remarks (optional)', Icons.note_add_outlined),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField('Date & Time', _formatDateTime(DateTime.now()), Icons.access_time),
            const SizedBox(height: 24),
            BeautifulSubmitButton(
              isLoading: _isSubmitting,
              onPressed: _selectedKeys.isEmpty ? null : _submitForm,
              idleLabel: 'Submit',
              loadingLabel: 'Submitting action...',
              icon: Icons.save,
              backgroundColor: AppActionTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF4F6F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search & add keys', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: _inputDecoration('Search by key name, zone, or ID', Icons.search),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _buildSelectedKeys(),
        const SizedBox(height: 12),
        _buildSearchResults(),
      ],
    );
  }

  Widget _buildSelectedKeys() {
    if (_selectedKeys.isEmpty) {
      return const Text('No keys selected yet.', style: TextStyle(color: Colors.black54));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedKeys.map((record) {
        return Chip(
          label: Text(record.keyName),
          deleteIcon: const Icon(Icons.close),
          onDeleted: () {
            setState(() => _selectedKeys.removeWhere((item) => item.keyId == record.keyId));
          },
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<KeyRecord>>(
      stream: KeyRecordRepository.watchAllKeys(),
      builder: (context, snapshot) {
        final allKeys = snapshot.data ?? const [];
        final query = _searchController.text.trim().toLowerCase();
        final results = allKeys.where((record) {
          final statusMatch = record.status == 'Available' || record.status == 'In Use';
          final queryMatch = query.isEmpty ||
              record.keyName.toLowerCase().contains(query) ||
              record.zone.toLowerCase().contains(query) ||
              record.keyId.toLowerCase().contains(query);
          return statusMatch && queryMatch;
        }).toList();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          ));
        }

        if (results.isEmpty) {
          return const Text('No available or in-use keys match your search.');
        }

        return Column(
          children: results.map((record) {
            final alreadyAdded = _selectedKeys.any((key) => key.keyId == record.keyId);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(record.keyName),
                subtitle: Text('${record.zone} • ${record.status}'),
                trailing: FilledButton(
                  onPressed: alreadyAdded
                      ? null
                      : () {
                          setState(() {
                            _selectedKeys.add(record);
                          });
                        },
                  child: Text(alreadyAdded ? 'Added' : 'Add'),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLockedKeysSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Locked keys', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            StreamBuilder<List<KeyRecord>>(
              stream: KeyRecordRepository.watchAllKeys(),
              builder: (context, snapshot) {
                final lockedKeys = snapshot.data
                        ?.where((record) => record.status == 'Lost' || record.status == 'No Return' || record.status == 'At Maintenance')
                        .toList() ??
                    const [];

                if (snapshot.connectionState == ConnectionState.waiting && lockedKeys.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (lockedKeys.isEmpty) {
                  return const Text('No lost, no-return, or at-maintenance keys currently locked.');
                }

                return Column(
                  children: lockedKeys.map((record) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(record.keyName),
                      subtitle: Text('${record.zone} • ${record.status}'),
                      trailing: Text(record.status, style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w700)),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) {
      return;
    }

    if (_selectedAction == null || _selectedKeys.isEmpty) {
      return;
    }

    final actionName = _actionLabel;
    setState(() => _isSubmitting = true);
    try {
      for (final record in _selectedKeys) {
        switch (_selectedAction) {
          case NoReturnAction.lost:
            await KeyRecordRepository.markLost(record);
            break;
          case NoReturnAction.noReturn:
            await KeyRecordRepository.markNoReturn(record);
            break;
          case NoReturnAction.maintenance:
            await KeyRecordRepository.markAtMaintenance(record);
            break;
          default:
            break;
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit action: $error')),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Action recorded'),
          content: Text(
            '${_selectedKeys.length} key(s) marked as $actionName by $_currentUserName.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime value) {
    final paddedMonth = value.month.toString().padLeft(2, '0');
    final paddedDay = value.day.toString().padLeft(2, '0');
    final paddedHour = value.hour.toString().padLeft(2, '0');
    final paddedMinute = value.minute.toString().padLeft(2, '0');
    return '$paddedDay/$paddedMonth/${value.year} $paddedHour:$paddedMinute';
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
    ),
  );
}
