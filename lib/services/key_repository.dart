import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class Borrower {
  Borrower({
    required this.name,
    required this.icPassport,
    required this.phone,
    required this.company,
    required this.department,
  });

  final String name;
  final String icPassport;
  final String phone;
  final String company;
  final String department;
}

class EventLog {
  EventLog({
    this.id,
    required this.action,
    required this.keyId,
    required this.keyName,
    required this.borrowerName,
    required this.icPassport,
    required this.phoneNumber,
    required this.company,
    required this.purpose,
    required this.dateTimeTaken,
    this.dateTimeReturned,
    required this.status,
    required this.lose,
    required this.actor,
    this.category = '',
    this.metadata = const {},
  });

  final String? id;
  final String action;
  final String keyId;
  final String keyName;
  final String borrowerName;
  final String icPassport;
  final String phoneNumber;
  final String company;
  final String purpose;
  final DateTime dateTimeTaken;
  final DateTime? dateTimeReturned;
  final String status;
  final bool lose;
  final String actor;
  final String category;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'keyId': keyId,
      'keyName': keyName,
      'borrowerName': borrowerName,
      'icPassport': icPassport,
      'phoneNumber': phoneNumber,
      'company': company,
      'purpose': purpose,
      'dateTimeTaken': Timestamp.fromDate(dateTimeTaken),
      'dateTimeReturned': dateTimeReturned == null ? null : Timestamp.fromDate(dateTimeReturned!),
      'status': status,
      'lose': lose,
      'actor': actor,
      'category': category,
      'metadata': metadata,
    };
  }

  static EventLog fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final takenTimestamp = data['dateTimeTaken'];
    final returnedTimestamp = data['dateTimeReturned'];
    final dateTimeTaken = takenTimestamp is Timestamp
        ? takenTimestamp.toDate()
        : takenTimestamp is DateTime
            ? takenTimestamp
            : DateTime.now();
    final dateTimeReturned = returnedTimestamp is Timestamp
        ? returnedTimestamp.toDate()
        : returnedTimestamp is DateTime
            ? returnedTimestamp
            : null;

    final metadataData = data['metadata'];
    final metadata = metadataData is Map<String, dynamic> ? metadataData : <String, dynamic>{};

    return EventLog(
      id: doc.id,
      action: data['action'] as String? ?? 'Unknown action',
      keyId: data['keyId'] as String? ?? '',
      keyName: data['keyName'] as String? ?? '',
      borrowerName: data['borrowerName'] as String? ?? '',
      icPassport: data['icPassport'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      company: data['company'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      dateTimeTaken: dateTimeTaken,
      dateTimeReturned: dateTimeReturned,
      status: data['status'] as String? ?? 'Unknown',
      lose: data['lose'] as bool? ?? false,
      actor: data['actor'] as String? ?? 'System',
      category: data['category'] as String? ?? '',
      metadata: metadata,
    );
  }

  EventLog copyWith({
    String? id,
    String? action,
    String? keyId,
    String? keyName,
    String? borrowerName,
    String? icPassport,
    String? phoneNumber,
    String? company,
    String? purpose,
    DateTime? dateTimeTaken,
    DateTime? dateTimeReturned,
    String? status,
    bool? lose,
    String? actor,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return EventLog(
      id: id ?? this.id,
      action: action ?? this.action,
      keyId: keyId ?? this.keyId,
      keyName: keyName ?? this.keyName,
      borrowerName: borrowerName ?? this.borrowerName,
      icPassport: icPassport ?? this.icPassport,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      company: company ?? this.company,
      purpose: purpose ?? this.purpose,
      dateTimeTaken: dateTimeTaken ?? this.dateTimeTaken,
      dateTimeReturned: dateTimeReturned ?? this.dateTimeReturned,
      status: status ?? this.status,
      lose: lose ?? this.lose,
      actor: actor ?? this.actor,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }
}

class KeyRecord {
  const KeyRecord({
    required this.keyId,
    required this.zone,
    required this.keyName,
    required this.borrowerName,
    required this.icPassport,
    required this.phoneNumber,
    required this.company,
    required this.purpose,
    required this.status,
    required this.takenAt,
    this.category = '',
    this.metadata = const {},
  });

  final String keyId;
  final String zone;
  final String keyName;
  final String borrowerName;
  final String icPassport;
  final String phoneNumber;
  final String company;
  final String purpose;
  final String status;
  final DateTime takenAt;
  final String category;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toFirestore() {
    return {
      'keyId': keyId,
      'zone': zone,
      'keyName': keyName,
      'borrowerName': borrowerName,
      'icPassport': icPassport,
      'phoneNumber': phoneNumber,
      'company': company,
      'purpose': purpose,
      'status': status,
      'takenAt': Timestamp.fromDate(takenAt),
      'category': category,
      'metadata': metadata,
    };
  }

  static KeyRecord fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final timestamp = data['takenAt'];
    final takenAt = timestamp is Timestamp
        ? timestamp.toDate()
        : timestamp is DateTime
            ? timestamp
            : DateTime.now();

    final metadataData = data['metadata'];
    final metadata = metadataData is Map<String, dynamic> ? metadataData : <String, dynamic>{};

    return KeyRecord(
      keyId: data['keyId'] as String? ?? doc.id,
      zone: data['zone'] as String? ?? '',
      keyName: data['keyName'] as String? ?? '',
      borrowerName: data['borrowerName'] as String? ?? '',
      icPassport: data['icPassport'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      company: data['company'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      status: data['status'] as String? ?? 'Available',
      takenAt: takenAt,
      category: data['category'] as String? ?? '',
      metadata: metadata,
    );
  }

  KeyRecord copyWith({
    String? keyId,
    String? zone,
    String? keyName,
    String? borrowerName,
    String? icPassport,
    String? phoneNumber,
    String? company,
    String? purpose,
    String? status,
    DateTime? takenAt,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    return KeyRecord(
      keyId: keyId ?? this.keyId,
      zone: zone ?? this.zone,
      keyName: keyName ?? this.keyName,
      borrowerName: borrowerName ?? this.borrowerName,
      icPassport: icPassport ?? this.icPassport,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      company: company ?? this.company,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
    );
  }
}

class KeyRecordRepository {
  static final List<KeyRecord> _keys = [
    KeyRecord(
      keyId: 'B1-AnchorTenant',
      zone: '23B',
      keyName: 'Anchor Tenant',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      status: 'Available',
      takenAt: DateTime(2026, 1, 1),
      category: 'Zone',
    ),
    KeyRecord(
      keyId: 'SRV-ROOM-01',
      zone: 'IT',
      keyName: 'Server Room',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      status: 'Available',
      takenAt: DateTime(2026, 1, 1),
      category: 'Zone',
    ),
    KeyRecord(
      keyId: 'WH-BAY-03',
      zone: 'Warehouse',
      keyName: 'Bay 3 Shutter',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      status: 'Available',
      takenAt: DateTime(2026, 1, 1),
      category: 'Zone',
    ),
    KeyRecord(
      keyId: 'ADM-A01',
      zone: 'Admin',
      keyName: 'Master Key A-01',
      borrowerName: 'Ali',
      icPassport: '900101-10-1234',
      phoneNumber: '0123456789',
      company: 'XYZ Contractor',
      purpose: 'Maintenance access',
      status: 'In Use',
      takenAt: DateTime(2026, 6, 30, 9, 20),
      category: 'Master Key',
    ),
    KeyRecord(
      keyId: 'CCTV-LOST-01',
      zone: 'Security',
      keyName: 'CCTV Room Key',
      borrowerName: 'Siti',
      icPassport: 'B23456789',
      phoneNumber: '0145558888',
      company: 'Security Service',
      purpose: 'Emergency access',
      status: 'Lost',
      takenAt: DateTime(2026, 6, 27, 15, 10),
      category: 'Zone',
    ),
    KeyRecord(
      keyId: 'NOCCTV-02',
      zone: 'Lobby',
      keyName: 'Lobby Fire Exit',
      borrowerName: 'Ravi',
      icPassport: '850505-14-7788',
      phoneNumber: '0198881122',
      company: 'Logistics Partner',
      purpose: 'Delivery access',
      status: 'No Return',
      takenAt: DateTime(2026, 6, 29, 17, 5),
      category: 'Zone',
    ),
  ];

  static final List<EventLog> _eventLogs = [
    EventLog(
      action: 'System started',
      keyId: 'SYSTEM',
      keyName: 'Key Record',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      dateTimeTaken: DateTime.now(),
      dateTimeReturned: null,
      status: 'System',
      lose: false,
      actor: 'System',
    ),
  ];

  static final StreamController<List<KeyRecord>> _keysController =
      StreamController<List<KeyRecord>>.broadcast()
        ..onListen = () => _keysController.add(List.unmodifiable(_keys));
  static final StreamController<List<EventLog>> _eventLogsController =
      StreamController<List<EventLog>>.broadcast()
        ..onListen = () => _eventLogsController.add(List.unmodifiable(_eventLogs));

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Firestore integration is enabled. The app will only use local fallback data
  // if Firebase has not been initialized successfully.
  static const bool _disableFirestore = false;
  static bool get _firestoreAvailable => !_disableFirestore && Firebase.apps.isNotEmpty;

  static CollectionReference<Map<String, dynamic>> get _keysCollection =>
      _firestore.collection('keys');
  static CollectionReference<Map<String, dynamic>> get _eventLogCollection =>
      _firestore.collection('event_log');
  static CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  static Future<void> _saveKey(KeyRecord key) async {
    if (!_firestoreAvailable) return;
    await _keysCollection.doc(key.keyId).set(key.toFirestore());
  }

  static Future<void> _saveEventLog(EventLog event) async {
    if (!_firestoreAvailable) return;
    final docRef = await _eventLogCollection.add(event.toFirestore());
    final updatedEvent = event.copyWith(id: docRef.id);
    final index = _eventLogs.indexWhere((existing) => identical(existing, event));
    if (index != -1) {
      _eventLogs[index] = updatedEvent;
      _eventLogsController.add(List.unmodifiable(_eventLogs));
    }
  }

  static Future<void> _saveNotification({
    required String title,
    required String body,
    required String keyId,
    required String category,
    required String recordedBy,
    String audience = 'allMembers',
  }) async {
    if (!_firestoreAvailable) return;
    await _notificationsCollection.add({
      'title': title,
      'body': body,
      'keyId': keyId,
      'category': category,
      'recordedBy': recordedBy,
      'audience': audience,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    });
  }

  static Future<void> _updateEventLog(EventLog event) async {
    if (!_firestoreAvailable || event.id == null) return;
    await _eventLogCollection.doc(event.id).update(event.toFirestore());
  }

  static Stream<List<KeyRecord>> watchAllKeys() {
    if (!_firestoreAvailable) {
      return _keysController.stream;
    }

    return _keysCollection.snapshots().map((snapshot) {
      final keys = snapshot.docs.map((doc) => KeyRecord.fromFirestore(doc)).toList();
      _keys
        ..clear()
        ..addAll(keys);
      _keysController.add(List.unmodifiable(_keys));
      return keys;
    });
  }

  static Stream<List<KeyRecord>> watchKeysInUse() {
    if (!_firestoreAvailable) {
      return _keysController.stream.map(
        (keys) => keys.where((key) => key.status == 'In Use').toList(),
      );
    }

    return _keysCollection
        .where('status', isEqualTo: 'In Use')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KeyRecord.fromFirestore(doc))
            .toList());
  }

  static Stream<List<EventLog>> watchEventLogs() {
    if (!_firestoreAvailable) {
      return _eventLogsController.stream;
    }

    return _eventLogCollection
        .orderBy('dateTimeTaken', descending: true)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs.map((doc) => EventLog.fromFirestore(doc)).toList();
          _eventLogs
            ..clear()
            ..addAll(events);
          _eventLogsController.add(List.unmodifiable(_eventLogs));
          return events;
        });
  }

  static List<KeyRecord> get availableKeys {
    return _keys.where((key) => key.status == 'Available').toList();
  }

  static List<KeyRecord> searchAvailableKeys(String query) {
    final normalized = query.trim().toLowerCase();
    return availableKeys.where((key) {
      return key.keyId.toLowerCase().contains(normalized) ||
          key.zone.toLowerCase().contains(normalized) ||
          key.keyName.toLowerCase().contains(normalized);
    }).toList();
  }

  static List<KeyRecord> searchKeys(String query) {
    final normalized = query.trim().toLowerCase();
    return _keys.where((key) {
      return key.keyId.toLowerCase().contains(normalized) ||
          key.zone.toLowerCase().contains(normalized) ||
          key.keyName.toLowerCase().contains(normalized) ||
          key.borrowerName.toLowerCase().contains(normalized) ||
          key.company.toLowerCase().contains(normalized) ||
          key.purpose.toLowerCase().contains(normalized);
    }).toList();
  }

  static bool isLockedStatus(String status) {
    return status == 'Lost' ||
        status == 'No Return' ||
        status == 'At Maintenance' ||
        status == 'Damaged' ||
        status == 'Replaced' ||
        status == 'Hand Over';
  }

  static Future<void> takeKeys(
    List<KeyRecord> keys,
    Borrower borrower,
    DateTime takenAt, {
    String recordedBy = 'Security Admin',
    String transactionStatus = 'In Use',
    Map<String, dynamic>? metadata,
  }) async {
    final effectiveMetadata = metadata ?? const <String, dynamic>{};
    final isHandOver = transactionStatus == 'Hand Over';

    for (final selected in keys) {
      if (isLockedStatus(selected.status)) {
        continue;
      }

      final index = _keys.indexWhere((key) => key.keyId == selected.keyId);
      if (index == -1) {
        continue;
      }

      _keys[index] = _keys[index].copyWith(
        status: isHandOver ? 'Hand Over' : 'In Use',
        borrowerName: borrower.name,
        icPassport: borrower.icPassport,
        phoneNumber: borrower.phone,
        company: borrower.company,
        purpose: _keys[index].purpose.isEmpty ? 'Routine access' : _keys[index].purpose,
        takenAt: takenAt,
      );
      final event = EventLog(
        action: isHandOver ? 'Key Handed Over' : 'Key Taken - In Use',
        keyId: _keys[index].keyId,
        keyName: _keys[index].keyName,
        borrowerName: borrower.name,
        icPassport: borrower.icPassport,
        phoneNumber: borrower.phone,
        company: borrower.company,
        purpose: _keys[index].purpose.isEmpty ? 'Routine access' : _keys[index].purpose,
        dateTimeTaken: takenAt,
        dateTimeReturned: null,
        status: isHandOver ? 'Hand Over' : 'In Use',
        lose: false,
        actor: recordedBy,
        metadata: effectiveMetadata,
      );
      await _appendEvent(event);

      if (_firestoreAvailable) {
        await _saveKey(_keys[index]).catchError((_) {});
        await _saveNotification(
          title: isHandOver
              ? 'Key ${_keys[index].zone}/${_keys[index].keyName} handed over to ${borrower.name}'
              : 'Key ${_keys[index].zone}/${_keys[index].keyName} now In Use by ${borrower.name}',
          body: isHandOver
              ? 'Key ${_keys[index].zone}/${_keys[index].keyName} was handed over by ${effectiveMetadata['handoverBy'] ?? recordedBy} to ${borrower.name}.${effectiveMetadata['documentReportNo'] == null || (effectiveMetadata['documentReportNo'] as String).trim().isEmpty ? '' : ' Report No: ${effectiveMetadata['documentReportNo']}.'}'
              : 'Key ${_keys[index].zone}/${_keys[index].keyName} is now In Use by ${borrower.name}.',
          keyId: _keys[index].keyId,
          category: _keys[index].category,
          recordedBy: recordedBy,
          audience: 'allMembers',
        ).catchError((_) {});
      }
    }

    _notifyKeys();
  }

  static Future<void> returnKey(KeyRecord record) async {
    final index = _keys.indexWhere((key) => key.keyId == record.keyId);
    if (index == -1) {
      return;
    }

    _keys[index] = _keys[index].copyWith(
      status: 'Available',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      takenAt: DateTime.now(),
    );

    await _updateReturnEvent(record);

    if (_firestoreAvailable) {
      await _saveKey(_keys[index]).catchError((_) {});
      await _saveNotification(
        title: 'Key Returned',
        body: 'Key ${_keys[index].zone}/${_keys[index].keyName} has been returned and is now Available.',
        keyId: _keys[index].keyId,
        category: _keys[index].category,
        recordedBy: 'Security Admin',
        audience: 'allMembers',
      ).catchError((_) {});
    }

    _notifyKeys();
  }

  static Future<void> markNoReturn(KeyRecord record) async {
    final index = _keys.indexWhere((key) => key.keyId == record.keyId);
    if (index == -1) {
      return;
    }

    _keys[index] = _keys[index].copyWith(status: 'No Return');
    final event = EventLog(
      action: 'No Return',
      keyId: _keys[index].keyId,
      keyName: _keys[index].keyName,
      borrowerName: _keys[index].borrowerName,
      icPassport: _keys[index].icPassport,
      phoneNumber: _keys[index].phoneNumber,
      company: _keys[index].company,
      purpose: _keys[index].purpose,
      dateTimeTaken: _keys[index].takenAt,
      dateTimeReturned: null,
      status: 'No Return',
      lose: false,
      actor: 'Security Admin',
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      await _saveKey(_keys[index]).catchError((_) {});
      await _saveNotification(
        title: 'No Return',
        body: 'Key ${_keys[index].zone}/${_keys[index].keyName} is now marked No Return.',
        keyId: _keys[index].keyId,
        category: _keys[index].category,
        recordedBy: 'Security Admin',
        audience: 'allMembers',
      ).catchError((_) {});
    }

    _notifyKeys();
  }

  static Future<void> markAtMaintenance(KeyRecord record) async {
    final index = _keys.indexWhere((key) => key.keyId == record.keyId);
    if (index == -1) {
      return;
    }

    _keys[index] = _keys[index].copyWith(status: 'At Maintenance');
    final event = EventLog(
      action: 'At Maintenance',
      keyId: _keys[index].keyId,
      keyName: _keys[index].keyName,
      borrowerName: _keys[index].borrowerName,
      icPassport: _keys[index].icPassport,
      phoneNumber: _keys[index].phoneNumber,
      company: _keys[index].company,
      purpose: _keys[index].purpose,
      dateTimeTaken: _keys[index].takenAt,
      dateTimeReturned: null,
      status: 'At Maintenance',
      lose: false,
      actor: 'Security Admin',
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      await _saveKey(_keys[index]).catchError((_) {});
    }

    _notifyKeys();
  }

  static Future<void> markLost(KeyRecord record) async {
    await _updateKeyStatus(
      record,
      status: 'Lost',
      action: 'Lost',
      actor: 'Security Admin',
      lose: true,
    );
  }

  static Future<void> markDamaged(KeyRecord record) async {
    await _updateKeyStatus(
      record,
      status: 'Damaged',
      action: 'Damaged',
      actor: 'Security Admin',
    );
  }

  static Future<void> markReplaced(KeyRecord record) async {
    await _updateKeyStatus(
      record,
      status: 'Replaced',
      action: 'New Key Replaced',
      actor: 'Security Admin',
    );
  }

  static Future<void> markHandOver(KeyRecord record, {String actor = 'Security Admin'}) async {
    await _updateKeyStatus(
      record,
      status: 'Hand Over',
      action: 'Hand Over',
      actor: actor,
    );
  }

  static Future<void> _updateKeyStatus(
    KeyRecord record, {
    required String status,
    required String action,
    required String actor,
    bool lose = false,
  }) async {
    final index = _keys.indexWhere((key) => key.keyId == record.keyId);
    if (index == -1) {
      return;
    }

    _keys[index] = _keys[index].copyWith(status: status);
    final event = EventLog(
      action: action,
      keyId: _keys[index].keyId,
      keyName: _keys[index].keyName,
      borrowerName: _keys[index].borrowerName,
      icPassport: _keys[index].icPassport,
      phoneNumber: _keys[index].phoneNumber,
      company: _keys[index].company,
      purpose: _keys[index].purpose,
      dateTimeTaken: _keys[index].takenAt,
      dateTimeReturned: null,
      status: status,
      lose: lose,
      actor: actor,
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      await _saveKey(_keys[index]).catchError((_) {});
    }

    _notifyKeys();
  }

  static Future<void> _appendEvent(EventLog event) async {
    _eventLogs.insert(0, event);
    _eventLogsController.add(List.unmodifiable(_eventLogs));
    if (_firestoreAvailable) {
      await _saveEventLog(event).catchError((_) {});
    }
  }

  static Future<void> _updateReturnEvent(KeyRecord record) async {
    final eventIndex = _eventLogs.indexWhere((event) =>
        event.keyId == record.keyId &&
        event.dateTimeReturned == null &&
        event.status == 'In Use');

    if (eventIndex == -1) {
      final returnEvent = EventLog(
        action: 'Returned',
        keyId: record.keyId,
        keyName: record.keyName,
        borrowerName: record.borrowerName,
        icPassport: record.icPassport,
        phoneNumber: record.phoneNumber,
        company: record.company,
        purpose: record.purpose,
        dateTimeTaken: record.takenAt,
        dateTimeReturned: DateTime.now(),
        status: 'Returned',
        lose: false,
        actor: 'Security Admin',
      );
      await _appendEvent(returnEvent);
      return;
    }

    final updated = _eventLogs[eventIndex].copyWith(
      dateTimeReturned: DateTime.now(),
      status: 'Returned',
      action: 'Returned',
    );
    _eventLogs[eventIndex] = updated;
    _eventLogsController.add(List.unmodifiable(_eventLogs));

    if (_firestoreAvailable) {
      await _updateEventLog(updated).catchError((_) {});
    }
  }

  static Future<void> registerNewKey({
    required String keyId,
    required String zone,
    required String keyName,
    required String category,
    required String status,
    required String recordedBy,
    Map<String, dynamic>? metadata,
  }) async {
    final normalizedStatus = status.isEmpty ? 'Available' : status;
    final key = KeyRecord(
      keyId: keyId,
      zone: zone,
      keyName: keyName,
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: metadata?['purpose'] as String? ?? '',
      status: normalizedStatus,
      takenAt: DateTime.now(),
      category: category,
      metadata: metadata ?? const {},
    );

    _keys.add(key);
    _keysController.add(List.unmodifiable(_keys));

    final event = EventLog(
      action: 'New Key Registered',
      keyId: key.keyId,
      keyName: key.keyName,
      borrowerName: key.borrowerName,
      icPassport: key.icPassport,
      phoneNumber: key.phoneNumber,
      company: key.company,
      purpose: key.purpose,
      dateTimeTaken: key.takenAt,
      dateTimeReturned: null,
      status: key.status,
      lose: false,
      actor: recordedBy,
      category: category,
      metadata: metadata ?? const {},
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      final qtyValue = metadata == null ? '' : metadata['qty']?.toString().trim() ?? '';
      final qtySuffix = qtyValue.isEmpty ? '' : ' Qty: $qtyValue.';
      await _saveKey(key).catchError((_) {});
      await _saveNotification(
        title: 'New Key Registered',
        body: 'A new key "$keyName" has been registered.$qtySuffix',
        keyId: key.keyId,
        category: category,
        recordedBy: recordedBy,
        audience: 'allMembers',
      ).catchError((_) {});
    }
  }

  static void _notifyKeys() {
    _keysController.add(List.unmodifiable(_keys));
  }
}
