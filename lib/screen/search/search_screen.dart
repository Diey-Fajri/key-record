import 'package:flutter/material.dart';
import '../../services/key_repository.dart';
import '../smart_detail/smart_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _queryController;
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _queryController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Search Keys'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  labelText: 'Search by key, borrower, company, or zone',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
                  ),
                ),
                onChanged: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<KeyRecord>>(
                  stream: KeyRecordRepository.watchAllKeys(),
                  builder: (context, snapshot) {
                    final allKeys = snapshot.data ?? const [];
                    final query = _query.trim().toLowerCase();
                    final results = allKeys.where((record) {
                      if (query.isEmpty) return true;
                      final label =
                          '${record.keyId} ${record.keyName} ${record.zone} ${record.borrowerName} ${record.company} ${record.purpose}'
                              .toLowerCase();
                      return label.contains(query);
                    }).toList();

                    if (snapshot.connectionState == ConnectionState.waiting && allKeys.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (results.isEmpty) {
                      return const Center(child: Text('No matching key records found.'));
                    }

                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = results[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE0E5E8)),
                          ),
                          child: ListTile(
                            title: Text(record.keyName),
                            subtitle: Text('${record.zone} • ${record.company}'),
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
      ),
    );
  }

  void _search(String query) {
    setState(() {
      _query = query;
    });
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
            : const Color(0xFFFFE5E5);
    final textColor = status == 'Available'
        ? const Color(0xFF2E7D32)
        : status == 'In Use'
            ? const Color(0xFF00695C)
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
