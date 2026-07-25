import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
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
