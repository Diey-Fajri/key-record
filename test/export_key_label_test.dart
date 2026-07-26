import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
  test('resolveExportKeyLabel uses labelNo for Others Key when keyName is empty', () {
    final event = EventLog(
      action: 'New Key Registered',
      keyId: 'KEY-001',
      keyName: '',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      dateTimeTaken: DateTime(2026, 7, 1),
      status: 'Available',
      lose: false,
      actor: 'System',
      category: 'Others Key',
      metadata: {
        'labelNo': 'Label 123',
      },
    );

    expect(
      KeyRecordRepository.resolveExportKeyLabel(event),
      'Label 123',
    );
  });

  test('resolveExportKeyLabel prefers keyName for Others Key when available', () {
    final event = EventLog(
      action: 'New Key Registered',
      keyId: 'KEY-002',
      keyName: 'Others Name',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      dateTimeTaken: DateTime(2026, 7, 1),
      status: 'Available',
      lose: false,
      actor: 'System',
      category: 'Others Key',
      metadata: {
        'labelNo': 'Label 456',
      },
    );

    expect(
      KeyRecordRepository.resolveExportKeyLabel(event),
      'Others Name',
    );
  });
}
