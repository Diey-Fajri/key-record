import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
  test('detail-backed maintenance actions persist staff and purpose metadata', () async {
    const keyId = 'TMP-STATUS-DETAIL-001';
    await KeyRecordRepository.registerNewKey(
      keyId: keyId,
      zone: 'Zone',
      keyName: 'Temp Detail Key',
      category: 'Zone',
      status: 'Available',
      recordedBy: 'Tester',
    );

    final created = KeyRecordRepository.searchKeys(keyId).firstWhere(
      (record) => record.keyId == keyId,
    );

    await KeyRecordRepository.markAtMaintenanceWithDetails(
      created,
      actor: 'Tester',
      metadata: {
        'staffName': 'Ali',
        'staffPhoneNumber': '0123456789',
        'department': 'Engineering',
        'purpose': 'Inspection',
        'date': '2026-07-26',
        'time': '10:30',
        'issueBy': 'Tester',
        'remark': 'Need servicing',
      },
    );

    final maintenance = KeyRecordRepository.searchKeys(keyId).firstWhere(
      (record) => record.keyId == keyId,
    );

    expect(maintenance.status, 'At Maintenance');
    expect(maintenance.metadata['staffName'], 'Ali');
    expect(maintenance.metadata['staffPhoneNumber'], '0123456789');
    expect(maintenance.metadata['department'], 'Engineering');
    expect(maintenance.metadata['purpose'], 'Inspection');
    expect(maintenance.metadata['issueBy'], 'Tester');
    expect(maintenance.metadata['remark'], 'Need servicing');

    final events = await KeyRecordRepository.watchEventLogs().first;
    final matching = events.where((event) => event.keyId == keyId).toList();
    expect(matching.firstWhere((event) => event.action == 'At Maintenance').metadata['staffName'], 'Ali');
  });

  test('quick status actions update key status and create event logs', () async {
    const keyId = 'TMP-STATUS-001';
    await KeyRecordRepository.registerNewKey(
      keyId: keyId,
      zone: 'Zone',
      keyName: 'Temp Status Key',
      category: 'Zone',
      status: 'Available',
      recordedBy: 'Tester',
    );

    final created = KeyRecordRepository.searchKeys(keyId).firstWhere(
      (record) => record.keyId == keyId,
    );

    await KeyRecordRepository.markAtMaintenance(created);
    final maintenance = KeyRecordRepository.searchKeys(keyId).firstWhere(
      (record) => record.keyId == keyId,
    );
    expect(maintenance.status, 'At Maintenance');

    await KeyRecordRepository.markAtManagement(created);
    final management = KeyRecordRepository.searchKeys(keyId).firstWhere(
      (record) => record.keyId == keyId,
    );
    expect(management.status, 'At Management');

    await KeyRecordRepository.markHighRisk(created);
    final highRisk = KeyRecordRepository.searchKeys(keyId).firstWhere(
      (record) => record.keyId == keyId,
    );
    expect(highRisk.status, 'High Risk');

    final events = await KeyRecordRepository.watchEventLogs().first;
    final matching = events.where((event) => event.keyId == keyId).toList();
    expect(
      matching.map((event) => event.action),
      containsAll(<String>['At Maintenance', 'At Management', 'High Risk']),
    );
  });
}
