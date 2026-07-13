import 'package:flutter/material.dart';

class SystemInfoScreen extends StatelessWidget {
  const SystemInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('System Info'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'LAPORAN KEMASKINI KEY RECORD APP',
                content: const [
                  _BulletSection(
                    heading: '1. SISTEM NOTIFIKASI FCM',
                    items: [
                      '✅ Baiki sistem simpan FCM token.',
                      '✅ Tukar struktur fcmTokens supaya setiap device mempunyai ID stabil.',
                      '✅ Buang penggunaan timestamp pada deviceId.',
                      '✅ Pastikan satu device tidak menghasilkan token duplicate setiap kali buka app.',
                      '',
                      'Testing:',
                      '✅ 2 device berjaya menerima notification.',
                      '✅ PM2 notification server berjaya hantar FCM.',
                      '✅ Found 2 FCM token documents.',
                      '✅ successCount: 2/2.',
                    ],
                  ),
                  _BulletSection(
                    heading: '2. ACTOR / USER TRACKING',
                    items: [
                      '✅ Audit semua tindakan pengguna.',
                      '✅ Buang penggunaan "Security Admin" sebagai actor untuk tindakan manusia.',
                      '',
                      'Supported actions:',
                      '✅ Register New Key',
                      '✅ Take Key',
                      '✅ Return Key',
                      '✅ Receive Key',
                      '✅ Handover Key',
                      '✅ Lost Key',
                      '✅ Damaged Key',
                      '✅ Maintenance',
                      '✅ Replace Key',
                      '✅ No Return',
                      '✅ Edit Key',
                      '✅ Delete Key',
                      '✅ Key Found',
                      '',
                      'All records:',
                      '- event_log',
                      '- notifications',
                      '- actor',
                      '- actorName',
                      '- recordedBy',
                      'use logged-in username.',
                    ],
                  ),
                  _BulletSection(
                    heading: '3. RETURN KEY DOUBLE ACTION BUG',
                    items: [
                      'Problem:',
                      'Return button sometimes required two taps.',
                      'Duplicate notification and event log created.',
                      '',
                      'Fix:',
                      '✅ Added in-flight protection.',
                      '✅ Disabled button during processing.',
                      '✅ Prevent duplicate processing.',
                      '',
                      'Result:',
                      '1 tap =',
                      '1 return action',
                      '1 notification',
                      '1 event log',
                    ],
                  ),
                  _BulletSection(
                    heading: '4. EVENT LOG FILTER',
                    items: [
                      '✅ Added in-app event filtering.',
                      '',
                      'Function:',
                      '- Clear/filter event logs inside app.',
                      '- Firestore data is not deleted.',
                      '- Hidden events remain hidden after refresh.',
                    ],
                  ),
                  _BulletSection(
                    heading: '5. LOGIN BUG',
                    items: [
                      'Problem:',
                      'After signup and returning to login page,',
                      'Sign In button loading does not stop.',
                      '',
                      'Fix:',
                      '✅ Reset loading state before navigation.',
                    ],
                  ),
                  _BulletSection(
                    heading: '6. ALL KEYS SORTING',
                    items: [
                      'Problem:',
                      '10A appeared before 1A.',
                      '',
                      'Fix:',
                      '✅ Added natural sorting.',
                      '',
                      'New order:',
                      '1A',
                      '2A',
                      '3A',
                      '10A',
                      '33A',
                    ],
                  ),
                  _BulletSection(
                    heading: '7. ALL KEYS DASHBOARD',
                    items: [
                      'Added live statistics:',
                      'Total Keys',
                      'In Use',
                      'Available',
                      'Not Available',
                      '',
                      'Features:',
                      '✅ Uses existing repository stream.',
                      '✅ Updates automatically when key status changes.',
                    ],
                  ),
                  _BulletSection(
                    heading: '8. UI IMPROVEMENT',
                    items: [
                      'Updates:',
                      '✅ All Keys screen audit.',
                      '✅ Added dashboard summary.',
                      '✅ Improved key visibility.',
                      '✅ Compact category/filter design.',
                    ],
                  ),
                  _BulletSection(
                    heading: '9. TESTING',
                    items: [
                      'Test:',
                      'flutter test key_repository_identity_test.dart',
                      '',
                      'Result:',
                      '✅ 2 tests passed',
                      '✅ 0 failed',
                    ],
                  ),
                  _BulletSection(
                    heading: 'STATUS',
                    items: [
                      'KeyRecord App is almost complete.',
                      '',
                      'Completed:',
                      '✅ Key management',
                      '✅ User tracking',
                      '✅ Event history',
                      '✅ FCM notification',
                      '✅ Multi device notification',
                      '✅ Dashboard statistics',
                      '✅ Key sorting',
                      '✅ Return/Login bug fixing',
                      '',
                      'Next:',
                      '- Final UI polishing',
                      '- APK release build',
                      '- Windows build',
                      '- Real user testing',
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.security_outlined, color: Color(0xFF1E3A5F), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Key Record App',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Unit Kawalan CCTV',
            style: TextStyle(fontSize: 14, color: Color(0xFF607D8B)),
          ),
          const SizedBox(height: 12),
          const Text(
            'System Update Report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF263238)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.heading, required this.items});

  final String heading;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 6),
          ...items.map((item) {
            if (item.isEmpty) {
              return const SizedBox(height: 4);
            }
            final isCheck = item.startsWith('✅');
            final isBullet = item.startsWith('- ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 16,
                    child: Icon(
                      isCheck ? Icons.check_circle_outline : (isBullet ? Icons.circle : Icons.circle_outlined),
                      size: 14,
                      color: isCheck ? const Color(0xFF2E7D32) : const Color(0xFF607D8B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isCheck ? const Color(0xFF1F2933) : const Color(0xFF52606D),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
