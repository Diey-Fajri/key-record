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
                title: 'Maklumat Kemas Kini (v1.0.9+10)',
                content: const [
                  _BulletSection(
                    heading: 'Penambahbaikan',
                    items: [
                      '• Menambah halaman Sejarah Notifikasi.',
                      '• Menambah butang Notifikasi (🔔) pada Dashboard.',
                      '• Menambah fungsi lihat, edit dan padam untuk Saved Person.',
                      '• Menambah pilihan Location menggunakan senarai dropdown semasa mengedit maklumat kunci.',
                      '• Menambah navigasi terus daripada carian Dashboard ke halaman Smart Detail.',
                    ],
                  ),
                  _BulletSection(
                    heading: 'Penambahbaikan Prestasi',
                    items: [
                      '• Meningkatkan kelajuan pembukaan aplikasi.',
                      '• Menambah baik pengendalian notifikasi FCM.',
                      '• Meningkatkan kestabilan penyegerakan data dengan Firestore.',
                    ],
                  ),
                  _BulletSection(
                    heading: 'Pembaikan Pepijat',
                    items: [
                      '• Memperbaiki isu Return Key yang memerlukan beberapa kali tekan.',
                      '• Memperbaiki paparan Keys Currently In Use yang tidak dikemas kini selepas pemulangan kunci.',
                      '• Memperbaiki paparan Smart Detail yang tidak dikemas kini selepas mengedit maklumat kunci.',
                      '• Memperbaiki isu penyegaran data dan paparan yang menggunakan maklumat lama (stale data).',
                      '• Memperbaiki navigasi serta beberapa isu kecil pada antara muka pengguna (UI).',
                    ],
                  ),
                  _BulletSection(
                    heading: 'Penutup',
                    items: [
                      'Terima kasih kerana menggunakan Key Record.',
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
