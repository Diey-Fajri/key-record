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
      'level': metadata['level']?.toString() ?? '',
      'zone': metadata['zone']?.toString() ?? '',
      'metadata': metadata,
    };
  }

  static EventLog fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final takenTimestamp = data['dateTimeTaken'];
    final createdAtTimestamp = data['createdAt'];
    final returnedTimestamp = data['dateTimeReturned'];
    final dateTimeTaken = takenTimestamp is Timestamp
        ? takenTimestamp.toDate()
        : takenTimestamp is DateTime
            ? takenTimestamp
        : createdAtTimestamp is Timestamp
          ? createdAtTimestamp.toDate()
          : createdAtTimestamp is DateTime
            ? createdAtTimestamp
            : DateTime.fromMillisecondsSinceEpoch(0);
    final dateTimeReturned = returnedTimestamp is Timestamp
        ? returnedTimestamp.toDate()
        : returnedTimestamp is DateTime
            ? returnedTimestamp
            : null;

    final metadataData = data['metadata'];
    final metadata = metadataData is Map ? Map<String, dynamic>.from(metadataData) : <String, dynamic>{};
    final levelFromData = data['level']?.toString().trim() ?? '';
    final zoneFromData = data['zone']?.toString().trim() ?? '';
    if (!metadata.containsKey('level') && levelFromData.isNotEmpty) {
      metadata['level'] = levelFromData;
    }
    if (!metadata.containsKey('zone') && zoneFromData.isNotEmpty) {
      metadata['zone'] = zoneFromData;
    }

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

    final status = data['status'] as String? ?? 'Unknown';
    final isAvailable = status == 'Available';

    final metadataData = data['metadata'];
    final metadata = metadataData is Map ? Map<String, dynamic>.from(metadataData) : <String, dynamic>{};

    return KeyRecord(
      keyId: data['keyId'] as String? ?? doc.id,
      zone: data['zone'] as String? ?? '',
      keyName: data['keyName'] as String? ?? '',
      borrowerName: isAvailable ? '' : (data['borrowerName'] as String? ?? ''),
      icPassport: isAvailable ? '' : (data['icPassport'] as String? ?? ''),
      phoneNumber: isAvailable ? '' : (data['phoneNumber'] as String? ?? ''),
      company: isAvailable ? '' : (data['company'] as String? ?? ''),
      purpose: isAvailable ? '' : (data['purpose'] as String? ?? ''),
      status: status,
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
    final normalizedKeyId = _normalizeKeyId(key.keyId);
    final snapshot = await _keysCollection.get();
    final matches = snapshot.docs.where((doc) {
      final data = doc.data();
      final docKeyId = data['keyId'] as String? ?? doc.id;
      return _normalizeKeyId(docKeyId) == normalizedKeyId;
    }).toList(growable: false);

    if (matches.isNotEmpty) {
      await matches.first.reference.set(key.toFirestore(), SetOptions(merge: true));
      // Clean up duplicates so one keyId maps to one Firestore document.
      for (final duplicate in matches.skip(1)) {
        await duplicate.reference.delete();
      }
      return;
    }

    await _keysCollection.doc(_keyDocId(key.keyId)).set(key.toFirestore());
  }

  // Firestore document IDs cannot contain '/'.
  static String _keyDocId(String keyId) {
    final normalized = keyId.trim();
    if (normalized.isEmpty) {
      return 'unknown-key';
    }
    return normalized.replaceAll('/', '_');
  }

  static String _normalizeKeyId(String keyId) {
    return keyId.trim().toUpperCase();
  }

  static String _dedupeIdentity(KeyRecord key) {
    final normalizedId = _normalizeKeyId(key.keyId);
    if (normalizedId.isNotEmpty && normalizedId != 'UNKNOWN-KEY') {
      return normalizedId;
    }

    final category = key.category.trim().toUpperCase();
    final zone = key.zone.trim().toUpperCase();
    final name = key.keyName.trim().toUpperCase();
    return '$category|$zone|$name';
  }

  static bool _isActiveStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'in use' || normalized == 'hand over';
  }

  static Future<void> _saveEventLog(EventLog event) async {
    if (!_firestoreAvailable) return;
    final payload = event.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _eventLogCollection.add(payload);
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

  static Stream<List<KeyRecord>> watchAllKeys() {
    if (!_firestoreAvailable) {
      return _keysController.stream;
    }

    return Stream<List<KeyRecord>>.multi((controller) {
      controller.add(List<KeyRecord>.unmodifiable(_keys));

      final subscription = _keysCollection.snapshots().listen(
        (snapshot) {
          final keys = _dedupeKeysById(
            snapshot.docs.map((doc) => KeyRecord.fromFirestore(doc)),
          );
          _keys
            ..clear()
            ..addAll(keys);
          final latest = List<KeyRecord>.unmodifiable(_keys);
          _keysController.add(latest);
          controller.add(latest);
        },
        onError: (_) {
          // Keep serving local cache if Firestore stream fails.
          controller.add(List<KeyRecord>.unmodifiable(_keys));
        },
      );

      controller.onCancel = () => subscription.cancel();
    });
  }

  static Future<void> refreshKeysFromFirestore() async {
    if (!_firestoreAvailable) {
      _keysController.add(List<KeyRecord>.unmodifiable(_keys));
      return;
    }

    final snapshot = await _keysCollection.get();
    final keys = _dedupeKeysById(
      snapshot.docs.map((doc) => KeyRecord.fromFirestore(doc)),
    );

    _keys
      ..clear()
      ..addAll(keys);
    _keysController.add(List<KeyRecord>.unmodifiable(_keys));
  }

  static Stream<List<KeyRecord>> watchKeysInUse() {
    return watchAllKeys().map(
      (keys) => keys
          .where((key) => _isActiveStatus(key.status))
          .toList(growable: false),
    );
  }

  static Stream<List<EventLog>> watchEventLogs() {
    if (!_firestoreAvailable) {
      return _eventLogsController.stream;
    }

    return Stream<List<EventLog>>.multi((controller) {
      // Always show currently cached events immediately while waiting for Firestore.
      controller.add(List<EventLog>.unmodifiable(_eventLogs));

      final subscription = _eventLogCollection
          .snapshots()
          .listen(
        (snapshot) {
          final events = snapshot.docs.map((doc) => EventLog.fromFirestore(doc)).toList()
            ..sort((a, b) => b.dateTimeTaken.compareTo(a.dateTimeTaken));
          _eventLogs
            ..clear()
            ..addAll(events);
          final latest = List<EventLog>.unmodifiable(_eventLogs);
          _eventLogsController.add(latest);
          controller.add(latest);
        },
        onError: (_) {
          // Do not break the UI stream; continue showing the latest cached events.
          controller.add(List<EventLog>.unmodifiable(_eventLogs));
        },
      );

      controller.onCancel = () => subscription.cancel();
    });
  }

  static Future<void> refreshEventLogsFromFirestore() async {
    if (!_firestoreAvailable) {
      _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
      return;
    }

    final snapshot = await _eventLogCollection.get();
    final events = snapshot.docs.map((doc) => EventLog.fromFirestore(doc)).toList()
      ..sort((a, b) => b.dateTimeTaken.compareTo(a.dateTimeTaken));

    _eventLogs
      ..clear()
      ..addAll(events);
    _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
  }

  static Future<void> clearEventLogs() async {
    _eventLogs.clear();
    _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
  }

  static Future<void> clearFilteredEventLogs(List<EventLog> eventsToClear) async {
    if (eventsToClear.isEmpty) {
      return;
    }

    final idSet = eventsToClear
        .map((event) => event.id)
        .whereType<String>()
        .toSet();

    final signatureSet = eventsToClear
        .map((event) => _eventSignature(event))
        .toSet();

    _eventLogs.removeWhere((existing) {
      final hasIdMatch = existing.id != null && idSet.contains(existing.id);
      final hasSignatureMatch = signatureSet.contains(_eventSignature(existing));
      return hasIdMatch || hasSignatureMatch;
    });
    _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
  }

  static String _eventSignature(EventLog event) {
    final takenMillis = event.dateTimeTaken.millisecondsSinceEpoch;
    return '${event.action}|${event.keyId}|${event.status}|$takenMillis|${event.actor}';
  }

  static Future<bool> refreshAllFromFirestore() async {
    if (!_firestoreAvailable) {
      _keysController.add(List<KeyRecord>.unmodifiable(_keys));
      _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
      return false;
    }

    await Future.wait([
      refreshKeysFromFirestore(),
      refreshEventLogsFromFirestore(),
    ]);
    return true;
  }

  static List<KeyRecord> _dedupeKeysById(Iterable<KeyRecord> keys) {
    final deduped = <String, KeyRecord>{};
    for (final key in keys) {
      final identity = _dedupeIdentity(key);
      final existing = deduped[identity];
      if (existing == null) {
        deduped[identity] = key;
        continue;
      }

      final existingActive = _isActiveStatus(existing.status);
      final currentActive = _isActiveStatus(key.status);

      if (!existingActive && currentActive) {
        deduped[identity] = key;
        continue;
      }

      if (existingActive == currentActive && key.takenAt.isAfter(existing.takenAt)) {
        deduped[identity] = key;
      }
    }
    return deduped.values.toList(growable: false);
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

      final purposeValue = effectiveMetadata['purpose']?.toString().trim().isNotEmpty == true
          ? effectiveMetadata['purpose'].toString().trim()
          : (_keys[index].purpose.isEmpty ? 'Routine access' : _keys[index].purpose);
      final mergedMetadata = Map<String, dynamic>.from(_keys[index].metadata)
        ..addAll(effectiveMetadata);

      _keys[index] = _keys[index].copyWith(
        status: isHandOver ? 'Hand Over' : 'In Use',
        borrowerName: borrower.name,
        icPassport: borrower.icPassport,
        phoneNumber: borrower.phone,
        company: borrower.company,
        purpose: purposeValue,
        takenAt: takenAt,
        metadata: mergedMetadata,
      );
      final event = EventLog(
        action: isHandOver ? 'Key Handed Over' : 'Key Taken - In Use',
        keyId: _keys[index].keyId,
        keyName: _keys[index].keyName,
        borrowerName: borrower.name,
        icPassport: borrower.icPassport,
        phoneNumber: borrower.phone,
        company: borrower.company,
        purpose: purposeValue,
        dateTimeTaken: takenAt,
        dateTimeReturned: null,
        status: isHandOver ? 'Hand Over' : 'In Use',
        lose: false,
        actor: recordedBy,
        category: _keys[index].category,
        metadata: mergedMetadata,
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
    final returnedAt = DateTime.now();
    final returnEvent = EventLog(
      action: 'Returned',
      keyId: record.keyId,
      keyName: record.keyName,
      borrowerName: record.borrowerName,
      icPassport: record.icPassport,
      phoneNumber: record.phoneNumber,
      company: record.company,
      purpose: record.purpose,
      dateTimeTaken: returnedAt,
      dateTimeReturned: returnedAt,
      status: 'Returned',
      lose: false,
      actor: 'Security Admin',
      category: record.category,
      metadata: record.metadata,
    );
    await _appendEvent(returnEvent);
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

    final normalizedNewId = _normalizeKeyId(keyId);
    final existingIndex = _keys.indexWhere((item) => _normalizeKeyId(item.keyId) == normalizedNewId);
    if (existingIndex == -1) {
      _keys.add(key);
    } else {
      _keys[existingIndex] = key;
    }
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

  static Future<void> updateRegisteredKeyDetails({
    required String keyId,
    required String zone,
    required String keyName,
    required String category,
    required String status,
    required String recordedBy,
    Map<String, dynamic>? metadata,
  }) async {
    final index = _keys.indexWhere((key) => key.keyId == keyId);
    KeyRecord? updatedRecord;

    if (index != -1) {
      final previous = _keys[index];
      final mergedMetadata = metadata ?? previous.metadata;
      final normalizedStatus = status.isEmpty ? previous.status : status;
      final isAvailable = normalizedStatus == 'Available';
      final purposeValue = isAvailable
          ? ''
          : (mergedMetadata['purpose']?.toString() ?? previous.purpose);

      _keys[index] = previous.copyWith(
        zone: zone,
        keyName: keyName,
        category: category,
        status: normalizedStatus,
        borrowerName: isAvailable ? '' : previous.borrowerName,
        icPassport: isAvailable ? '' : previous.icPassport,
        phoneNumber: isAvailable ? '' : previous.phoneNumber,
        company: isAvailable ? '' : previous.company,
        purpose: purposeValue,
        metadata: mergedMetadata,
      );
      updatedRecord = _keys[index];

      _keysController.add(List.unmodifiable(_keys));

      final event = EventLog(
        action: 'Key Details Edited',
        keyId: updatedRecord.keyId,
        keyName: updatedRecord.keyName,
        borrowerName: updatedRecord.borrowerName,
        icPassport: updatedRecord.icPassport,
        phoneNumber: updatedRecord.phoneNumber,
        company: updatedRecord.company,
        purpose: updatedRecord.purpose,
        dateTimeTaken: DateTime.now(),
        dateTimeReturned: null,
        status: updatedRecord.status,
        lose: false,
        actor: recordedBy,
        category: updatedRecord.category,
        metadata: mergedMetadata,
      );
      await _appendEvent(event);
    }

    if (_firestoreAvailable) {
      if (updatedRecord != null) {
        await _saveKey(updatedRecord).catchError((_) {});
      } else {
        final mergedMetadata = metadata ?? const <String, dynamic>{};
        await _keysCollection.doc(_keyDocId(keyId)).set({
          'keyId': keyId,
          'zone': zone,
          'keyName': keyName,
          'category': category,
          'status': status,
          'purpose': mergedMetadata['purpose']?.toString() ?? '',
          'metadata': mergedMetadata,
          'takenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError((_) {});
      }

      await _saveNotification(
        title: 'Key Details Updated',
        body: 'Key "$keyName" details were updated by $recordedBy.',
        keyId: keyId,
        category: category,
        recordedBy: recordedBy,
        audience: 'allMembers',
      ).catchError((_) {});
    }

    _notifyKeys();
  }

  static Future<void> deleteKey(
    KeyRecord record, {
    String recordedBy = 'Security Admin',
  }) async {
    final index = _keys.indexWhere((key) => key.keyId == record.keyId);
    if (index == -1) {
      return;
    }

    final deleted = _keys.removeAt(index);
    _keysController.add(List.unmodifiable(_keys));

    final event = EventLog(
      action: 'Key Deleted',
      keyId: deleted.keyId,
      keyName: deleted.keyName,
      borrowerName: deleted.borrowerName,
      icPassport: deleted.icPassport,
      phoneNumber: deleted.phoneNumber,
      company: deleted.company,
      purpose: deleted.purpose,
      dateTimeTaken: DateTime.now(),
      dateTimeReturned: null,
      status: 'Deleted',
      lose: false,
      actor: recordedBy,
      category: deleted.category,
      metadata: deleted.metadata,
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      await _keysCollection.doc(_keyDocId(deleted.keyId)).delete().catchError((_) {});
      await _saveNotification(
        title: 'Key Deleted',
        body: 'Key ${deleted.zone}/${deleted.keyName} was deleted by $recordedBy.',
        keyId: deleted.keyId,
        category: deleted.category,
        recordedBy: recordedBy,
        audience: 'allMembers',
      ).catchError((_) {});
    }

    _notifyKeys();
  }

  static void _notifyKeys() {
    _keysController.add(List.unmodifiable(_keys));
  }
}
