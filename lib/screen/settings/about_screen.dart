import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'About This Application',
                body: 'Key Record is a digital key management system developed to help CCTV Control Unit record, monitor and control security key movement.\n\nThis application replaces manual key records with a digital system to improve accuracy, security and efficiency in key management.',
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Main Features',
                body: '🔑 Key Management\nManage key registration, borrowing, returning and key status.\n\n👤 User Tracking\nEvery action is recorded based on the logged-in user.\n\n📝 Event History\nMaintain complete key activity history for audit purposes.\n\n🔔 Real-Time Notification\nReceive notifications when key status changes.\n\n📊 Dashboard Monitoring\nView current key statistics and status summary.',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Security Purpose',
                body: 'Developed to support security operations, key monitoring and audit records for CCTV Control Unit.',
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '© 2026 Key Record SSC\nAll Rights Reserved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'Key Record SSC',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unit Kawalan CCTV',
            style: TextStyle(fontSize: 14, color: Color(0xFF607D8B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Security Key Management System',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF263238)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF52606D)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Application Information',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF263238)),
          ),
          const SizedBox(height: 12),
          _infoRow('App Name', 'Key Record SSC'),
          _infoRow('Department', 'Unit Kawalan CCTV'),
          _infoRow('Version', '1.0.7+8'),
          _infoRow('Platform', 'Android / Windows'),
          _infoRow('Developer', 'Fajri (S17380)'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF607D8B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2933)),
            ),
          ),
        ],
      ),
    );
  }
}
