import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

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

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icPassport': icPassport,
      'phone': phone,
      'company': company,
      'department': department,
    };
  }

  static Borrower fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Borrower(
      name: data['name'] as String? ?? '',
      icPassport: data['icPassport'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      company: data['company'] as String? ?? '',
      department: data['department'] as String? ?? '',
    );
  }
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
      'dateTimeReturned': dateTimeReturned == null
          ? null
          : Timestamp.fromDate(dateTimeReturned!),
      'status': status,
      'lose': lose,
      'actor': actor,
      'actorName': actor,
      'category': category,
      'level': metadata['level']?.toString() ?? '',
      'zone': metadata['zone']?.toString() ?? '',
      'metadata': metadata,
    };
  }

  static EventLog fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
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
    final metadata = metadataData is Map
        ? Map<String, dynamic>.from(metadataData)
        : <String, dynamic>{};
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
    this.docId,
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

  final String? docId;
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

  static KeyRecord fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
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
    final metadata = metadataData is Map
        ? Map<String, dynamic>.from(metadataData)
        : <String, dynamic>{};

    return KeyRecord(
      docId: doc.id,
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
    String? docId,
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
      docId: docId ?? this.docId,
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

  static final List<Borrower> _savedBorrowers = <Borrower>[];

  static final StreamController<List<KeyRecord>> _keysController =
      StreamController<List<KeyRecord>>.broadcast()
        ..onListen = () => _keysController.add(List.unmodifiable(_keys));
  static final StreamController<List<EventLog>> _eventLogsController =
      StreamController<List<EventLog>>.broadcast()
        ..onListen = () =>
            _eventLogsController.add(List.unmodifiable(_eventLogs));
  static final StreamController<List<Borrower>> _savedBorrowersController =
      StreamController<List<Borrower>>.broadcast()
        ..onListen = () =>
            _savedBorrowersController.add(List.unmodifiable(_savedBorrowers));
  // Persisted set of hidden event signatures (filtered out in-app)
  static final Set<String> _hiddenEventSignatures = <String>{};
  static bool _hiddenSignaturesLoaded = false;
  static const String _kHiddenEventSignaturesKey = 'hidden_event_signatures';

  static Future<void> _ensureHiddenSignaturesLoaded() async {
    if (_hiddenSignaturesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kHiddenEventSignaturesKey) ?? <String>[];
      _hiddenEventSignatures.addAll(list);
      // Remove any matching events from the in-memory cache so they stay hidden in-app.
      if (_hiddenEventSignatures.isNotEmpty && _eventLogs.isNotEmpty) {
        _eventLogs.removeWhere((existing) => _hiddenEventSignatures.contains(_eventSignature(existing)));
        _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
      }
    } catch (error) {
      debugPrint('[KeyRepository] failed to load hidden event signatures: $error');
    }
    _hiddenSignaturesLoaded = true;
  }

  static Future<void> _saveHiddenSignatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kHiddenEventSignaturesKey, _hiddenEventSignatures.toList());
    } catch (error) {
      debugPrint('[KeyRepository] failed to save hidden event signatures: $error');
    }
  }

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Firestore integration is enabled. The app will only use local fallback data
  // if Firebase has not been initialized successfully.
  static const bool _disableFirestore = false;
  static bool get _firestoreAvailable =>
      !_disableFirestore && Firebase.apps.isNotEmpty;

  static String resolveActor(String? actor) {
    final trimmed = actor?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return AuthService.activeUser.trim();
  }

  static CollectionReference<Map<String, dynamic>> get _keysCollection =>
      _firestore.collection('keys');
  static CollectionReference<Map<String, dynamic>> get _eventLogCollection =>
      _firestore.collection('event_log');
  static CollectionReference<Map<String, dynamic>>
  get _notificationsCollection => _firestore.collection('notifications');
  static CollectionReference<Map<String, dynamic>>
  get _savedPersonsCollection => _firestore.collection('saved_persons');

  // Track in-flight return operations to prevent duplicate processing
  static final Set<String> _inFlightReturnKeys = <String>{};

  static Future<void> _saveKey(KeyRecord key) async {
    if (!_firestoreAvailable) return;
    final targetDocId = (key.docId?.trim().isNotEmpty ?? false)
        ? key.docId!.trim()
        : _keyDocIdForRecord(key);
    final targetRef = _keysCollection.doc(targetDocId);

    // Write deterministic doc first so updates are not blocked by full-collection scans.
    await targetRef.set(key.toFirestore(), SetOptions(merge: true));

    // Update any existing docs for the same logical key.
    if (key.keyId.trim().isNotEmpty) {
      final keyIdSnapshot = await _keysCollection
          .where('keyId', isEqualTo: key.keyId.trim())
          .get();
      for (final doc in keyIdSnapshot.docs) {
        if (doc.id == targetDocId) {
          continue;
        }
        await doc.reference.set(key.toFirestore(), SetOptions(merge: true));
      }
    }

    final snapshot = await _keysCollection.get();
    for (final doc in snapshot.docs) {
      if (doc.id == targetDocId) {
        continue;
      }
      final existing = KeyRecord.fromFirestore(doc);
      if (!_sameLogicalKey(existing, key)) {
        continue;
      }
      await doc.reference.set(key.toFirestore(), SetOptions(merge: true));
    }
  }

  static Future<void> _persistKeyToFirestore(KeyRecord key) async {
    if (!_firestoreAvailable) {
      return;
    }

    final targetDocId = key.docId?.trim() ?? '';
    if (targetDocId.isNotEmpty) {
      await _keysCollection
          .doc(targetDocId)
          .set(key.toFirestore(), SetOptions(merge: true));
      return;
    }

    await _saveKey(key);
  }

  // Firestore document IDs cannot contain '/'.
  static String _keyDocId(String keyId) {
    final normalized = keyId.trim();
    if (normalized.isEmpty) {
      return 'unknown-key';
    }
    return normalized.replaceAll('/', '_');
  }

  static String _keyDocIdForRecord(KeyRecord key) {
    final base = _logicalKeyIdentity(
      key,
    ).replaceAll('/', '_').replaceAll(' ', '_');
    return base.isEmpty ? _keyDocId(key.keyId) : base;
  }

  static String _normalizeKeyId(String keyId) {
    return keyId.trim().toUpperCase();
  }

  static String _dedupeIdentity(KeyRecord key) {
    final logicalIdentity = _logicalKeyIdentity(key);
    if (logicalIdentity.isNotEmpty) {
      return logicalIdentity;
    }

    final docId = key.docId?.trim() ?? '';
    if (docId.isNotEmpty) {
      return 'DOC:$docId';
    }

    return _keyDocId(key.keyId);
  }

  static String _identityMetadataSignature(KeyRecord key) {
    final category = key.category.trim().toLowerCase();
    switch (category) {
      case 'master key':
        return 'master:${(key.metadata['masterKey'] ?? key.keyName).toString().trim().toLowerCase()}';
      case 'lot':
        return 'lot:${(key.metadata['lotKey'] ?? key.keyName).toString().trim().toLowerCase()}';
      case 'roller shutter':
        return 'roller:${(key.metadata['rollerLevelNo'] ?? '').toString().trim().toLowerCase()}|${(key.metadata['rollerNumber'] ?? '').toString().trim().toLowerCase()}';
      default:
        return '';
    }
  }

  static String _logicalKeyIdentity(KeyRecord key) {
    final normalizedId = _normalizeKeyId(key.keyId);
    final category = key.category.trim().toUpperCase();
    final name = key.keyName.trim().toUpperCase();
    final level = _normalizedRecordLevel(key);
    final zone = _normalizedRecordZone(key);
    return '$normalizedId|$category|$level|$zone|$name';
  }

  static String _normalizedRecordLevel(KeyRecord key) {
    final metadataLevel =
        key.metadata['level']?.toString().trim().toUpperCase() ?? '';
    if (metadataLevel.isNotEmpty) {
      return metadataLevel;
    }

    final rollerLevel =
        key.metadata['rollerLevelNo']?.toString().trim().toUpperCase() ?? '';
    final rollerMatch = RegExp(
      r'B2|B1|L\d{1,2}|LEVEL\s*\d{1,2}',
    ).firstMatch(rollerLevel);
    if (rollerMatch != null) {
      return rollerMatch.group(0)!.replaceAll('LEVEL ', 'L');
    }

    final zoneValue = key.zone.trim().toUpperCase();
    final zoneMatch = RegExp(
      r'B2|B1|L\d{1,2}|LEVEL\s*\d{1,2}',
    ).firstMatch(zoneValue);
    if (zoneMatch != null) {
      return zoneMatch.group(0)!.replaceAll('LEVEL ', 'L');
    }

    return '';
  }

  static String _normalizedRecordZone(KeyRecord key) {
    final metadataZone =
        key.metadata['zone']?.toString().trim().toUpperCase() ?? '';
    if (metadataZone.isNotEmpty) {
      return metadataZone;
    }
    return key.zone.trim().toUpperCase();
  }

  static bool recordsMatch(KeyRecord left, KeyRecord right) {
    final leftDocId = left.docId?.trim() ?? '';
    final rightDocId = right.docId?.trim() ?? '';
    if (leftDocId.isNotEmpty &&
        rightDocId.isNotEmpty &&
        leftDocId == rightDocId) {
      return true;
    }

    final sameKeyId =
        _normalizeKeyId(left.keyId) == _normalizeKeyId(right.keyId);
    final sameCategory =
        left.category.trim().toLowerCase() ==
        right.category.trim().toLowerCase();
    final sameName =
        left.keyName.trim().toLowerCase() == right.keyName.trim().toLowerCase();
    final sameLevel =
        _normalizedRecordLevel(left) == _normalizedRecordLevel(right);
    final sameZone =
        _normalizedRecordZone(left) == _normalizedRecordZone(right);

    if (sameKeyId && sameCategory && sameName && sameLevel && sameZone) {
      return true;
    }

    final leftSpecific = _identityMetadataSignature(left);
    final rightSpecific = _identityMetadataSignature(right);
    if (leftSpecific.isNotEmpty &&
        rightSpecific.isNotEmpty &&
        leftSpecific == rightSpecific) {
      return true;
    }

    return _logicalKeyIdentity(left) == _logicalKeyIdentity(right);
  }

  static bool _sameLogicalKey(KeyRecord left, KeyRecord right) {
    return recordsMatch(left, right);
  }

  static int _indexForRecord(KeyRecord target) {
    final targetDocId = target.docId?.trim() ?? '';

    // Priority 1: Match by docId
    if (targetDocId.isNotEmpty) {
      final indexByDoc = _keys.indexWhere(
        (key) => (key.docId?.trim() ?? '') == targetDocId,
      );
      if (indexByDoc != -1) return indexByDoc;
    }

    final targetKeyId = target.keyId.trim().toUpperCase();

    // Priority 2: Match by keyId (paling penting)
    return _keys.indexWhere((key) {
      final existingKeyId = key.keyId.trim().toUpperCase();

      if (existingKeyId == targetKeyId) return true;

      // Fallback ke logical key kalau keyId tak match
      return _sameLogicalKey(key, target);
    });
  }

  static bool _isActiveStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'in use' || normalized == 'hand over';
  }

  static bool isNotAvailableStatus(String status) {
    return status.trim().toLowerCase() == 'not available';
  }

  static String _normalizeBorrowerIdentity(Borrower borrower) {
    final ic = borrower.icPassport.trim().toUpperCase();
    if (ic.isNotEmpty) {
      return ic;
    }
    return borrower.name.trim().toUpperCase();
  }

  static String _savedBorrowerDocId(Borrower borrower) {
    final identity = _normalizeBorrowerIdentity(
      borrower,
    ).replaceAll('/', '_').replaceAll(' ', '_');
    return identity.isEmpty ? 'UNKNOWN_BORROWER' : identity;
  }

  static void _upsertSavedBorrowerLocal(Borrower borrower) {
    final identity = _normalizeBorrowerIdentity(borrower);
    final index = _savedBorrowers.indexWhere(
      (item) => _normalizeBorrowerIdentity(item) == identity,
    );

    if (index == -1) {
      _savedBorrowers.add(borrower);
    } else {
      _savedBorrowers[index] = borrower;
    }

    _savedBorrowers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    _savedBorrowersController.add(List.unmodifiable(_savedBorrowers));
  }

  static Future<bool> saveBorrowerProfile(
    Borrower borrower, {
    String recordedBy = '',
  }) async {
    final normalized = Borrower(
      name: borrower.name.trim(),
      icPassport: borrower.icPassport.trim(),
      phone: borrower.phone.trim(),
      company: borrower.company.trim(),
      department: borrower.department.trim(),
    );
    if (normalized.name.isEmpty) {
      return false;
    }

    final identity = _normalizeBorrowerIdentity(normalized);
    final existed = _savedBorrowers.any(
      (item) => _normalizeBorrowerIdentity(item) == identity,
    );

    _upsertSavedBorrowerLocal(normalized);

    if (_firestoreAvailable) {
      await _savedPersonsCollection.doc(_savedBorrowerDocId(normalized)).set({
        ...normalized.toFirestore(),
        'recordedBy': resolveActor(recordedBy),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return !existed;
  }

  static Stream<List<Borrower>> watchSavedBorrowers() {
    if (!_firestoreAvailable) {
      return _savedBorrowersController.stream;
    }

    return Stream<List<Borrower>>.multi((controller) {
      controller.add(List<Borrower>.unmodifiable(_savedBorrowers));

      final localSubscription = _savedBorrowersController.stream.listen(
        controller.add,
        onError: controller.addError,
      );

      final subscription = _savedPersonsCollection.snapshots().listen(
        (snapshot) {
          final borrowers = snapshot.docs.map(Borrower.fromFirestore).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          _savedBorrowers
            ..clear()
            ..addAll(borrowers);
          final latest = List<Borrower>.unmodifiable(_savedBorrowers);
          _savedBorrowersController.add(latest);
          controller.add(latest);
        },
        onError: (_) {
          controller.add(List<Borrower>.unmodifiable(_savedBorrowers));
        },
      );

      controller.onCancel = () {
        subscription.cancel();
        localSubscription.cancel();
      };
    });
  }

  static Future<void> refreshSavedBorrowersFromFirestore() async {
    if (!_firestoreAvailable) {
      _savedBorrowersController.add(
        List<Borrower>.unmodifiable(_savedBorrowers),
      );
      return;
    }

    final snapshot = await _savedPersonsCollection.get();
    final borrowers = snapshot.docs.map(Borrower.fromFirestore).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _savedBorrowers
      ..clear()
      ..addAll(borrowers);
    _savedBorrowersController.add(List<Borrower>.unmodifiable(_savedBorrowers));
  }

  static Future<void> _saveEventLog(EventLog event) async {
    if (!_firestoreAvailable) return;
    final payload = event.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _eventLogCollection.add(payload);
    final updatedEvent = event.copyWith(id: docRef.id);
    final index = _eventLogs.indexWhere(
      (existing) => identical(existing, event),
    );
    if (index != -1) {
      _eventLogs[index] = updatedEvent;
      _eventLogsController.add(List.unmodifiable(_eventLogs));
    }
  }

  static Future<void> _saveNotification({
    required String action,
    required String body,
    required String keyId,
    required String category,
    required String recordedBy,
    String audience = 'allMembers',
    String type = 'activity',
    String? title,
    Map<String, dynamic>? extraData,
  }) async {
    if (!_firestoreAvailable) return;
    final actorValue = resolveActor(recordedBy);
    final actorName = actorValue.isNotEmpty ? actorValue : recordedBy.trim();

    final payload = <String, dynamic>{
      'title': title ?? action,
      'body': body,
      'type': type,
      'keyId': keyId,
      'category': category,
      'recordedBy': recordedBy,
      'actorName': actorName,
      'audience': audience,
      'createdAt': FieldValue.serverTimestamp(),
      'fcmSent': false,
      'readBy': <String>[],
    };
    if (extraData != null) {
      payload.addAll(extraData);
    }
    await _notificationsCollection.add(payload);
  }

  static Stream<List<KeyRecord>> watchAllKeys() {
    if (!_firestoreAvailable) {
      return _keysController.stream;
    }

    return Stream<List<KeyRecord>>.multi((controller) {
      controller.add(List<KeyRecord>.unmodifiable(_keys));

      final localSubscription = _keysController.stream.listen(
        controller.add,
        onError: controller.addError,
      );

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

      controller.onCancel = () {
        subscription.cancel();
        localSubscription.cancel();
      };
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
      // Ensure hidden signatures are loaded before streaming Firestore results.
      _ensureHiddenSignaturesLoaded().then((_) {
        // Always show currently cached events immediately while waiting for Firestore.
        controller.add(List<EventLog>.unmodifiable(_eventLogs));

        final localSubscription = _eventLogsController.stream.listen(
          controller.add,
          onError: controller.addError,
        );

        final subscription = _eventLogCollection.snapshots().listen((snapshot) async {
          final events = snapshot.docs.map((doc) => EventLog.fromFirestore(doc)).toList();
          // Filter out any events the user has hidden.
          final visible = events.where((e) => !_hiddenEventSignatures.contains(_eventSignature(e))).toList()
            ..sort((a, b) => b.dateTimeTaken.compareTo(a.dateTimeTaken));

          _eventLogs
            ..clear()
            ..addAll(visible);
          final latest = List<EventLog>.unmodifiable(_eventLogs);
          _eventLogsController.add(latest);
          controller.add(latest);
        }, onError: (_) {
          // Do not break the UI stream; continue showing the latest cached events.
          controller.add(List<EventLog>.unmodifiable(_eventLogs));
        });

        controller.onCancel = () {
          subscription.cancel();
          localSubscription.cancel();
        };
      });
    });
  }

  static Future<void> refreshEventLogsFromFirestore() async {
    if (!_firestoreAvailable) {
      _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
      return;
    }

    await _ensureHiddenSignaturesLoaded();

    final snapshot = await _eventLogCollection.get();
    var events = snapshot.docs.map((doc) => EventLog.fromFirestore(doc)).toList();
    // Filter out any events that the user has hidden (in-app only)
    events = events.where((e) => !_hiddenEventSignatures.contains(_eventSignature(e))).toList();
    events.sort((a, b) => b.dateTimeTaken.compareTo(a.dateTimeTaken));

    _eventLogs
      ..clear()
      ..addAll(events);
    _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
  }

  static Future<void> clearEventLogs() async {
    _eventLogs.clear();
    _eventLogsController.add(List<EventLog>.unmodifiable(_eventLogs));
  }

  static Future<void> clearFilteredEventLogs(
    List<EventLog> eventsToClear,
  ) async {
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
    // Persist signatures so filtered events remain hidden across refreshes (app-only)
    await _ensureHiddenSignaturesLoaded();
    _hiddenEventSignatures.addAll(signatureSet);
    await _saveHiddenSignatures();

    _eventLogs.removeWhere((existing) {
      final hasIdMatch = existing.id != null && idSet.contains(existing.id);
      final hasSignatureMatch = signatureSet.contains(
        _eventSignature(existing),
      );
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
      _savedBorrowersController.add(
        List<Borrower>.unmodifiable(_savedBorrowers),
      );
      return false;
    }

    await Future.wait([
      refreshKeysFromFirestore(),
      refreshEventLogsFromFirestore(),
      refreshSavedBorrowersFromFirestore(),
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

      if (existingActive == currentActive &&
          key.takenAt.isAfter(existing.takenAt)) {
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

  static List<KeyRecord> searchKeysFlexible(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const <KeyRecord>[];
    }

    final results = _keys
        .where((key) {
          final metadata = key.metadata;
          final parts = <String>[
            key.keyId,
            key.zone,
            key.keyName,
            key.borrowerName,
            key.company,
            key.purpose,
            key.status,
            key.category,
            metadata['level']?.toString() ?? '',
            metadata['zone']?.toString() ?? '',
            metadata['location']?.toString() ?? '',
            metadata['position']?.toString() ?? '',
            metadata['doorId']?.toString() ?? '',
            metadata['masterKey']?.toString() ?? '',
            metadata['lotKey']?.toString() ?? '',
            metadata['rollerLevelNo']?.toString() ?? '',
            metadata['rollerNumber']?.toString() ?? '',
            metadata['staffName']?.toString() ?? '',
            metadata['othersName']?.toString() ?? '',
            metadata['department']?.toString() ?? '',
            metadata['remarks']?.toString() ?? '',
          ];
          final haystack = parts.join(' ').toLowerCase();
          return haystack.contains(normalized);
        })
        .toList(growable: false);

    results.sort((a, b) {
      final scoreA = _searchScore(a, normalized);
      final scoreB = _searchScore(b, normalized);
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      return a.keyId.compareTo(b.keyId);
    });

    return results;
  }

  static List<KeyRecord> searchKeyHints(String query, {int limit = 6}) {
    final results = searchKeysFlexible(query);
    if (results.length <= limit) {
      return results;
    }
    return results.take(limit).toList(growable: false);
  }

  static int _searchScore(KeyRecord key, String normalizedQuery) {
    var score = 0;
    final keyId = key.keyId.toLowerCase();
    final keyName = key.keyName.toLowerCase();
    final zone = key.zone.toLowerCase();
    final level = key.metadata['level']?.toString().toLowerCase() ?? '';
    final metadataZone = key.metadata['zone']?.toString().toLowerCase() ?? '';

    if (keyId == normalizedQuery) score += 120;
    if (keyName == normalizedQuery) score += 100;
    if (zone == normalizedQuery || metadataZone == normalizedQuery) score += 90;
    if (level == normalizedQuery) score += 70;
    if (keyId.startsWith(normalizedQuery)) {
      score += 60;
    }
    if (keyName.startsWith(normalizedQuery)) {
      score += 50;
    }
    if (zone.startsWith(normalizedQuery) ||
        metadataZone.startsWith(normalizedQuery)) {
      score += 40;
    }
    if (keyId.contains(normalizedQuery)) {
      score += 20;
    }
    if (keyName.contains(normalizedQuery)) {
      score += 15;
    }
    if (zone.contains(normalizedQuery) ||
        metadataZone.contains(normalizedQuery)) {
      score += 10;
    }
    return score;
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
    String recordedBy = '',
    String transactionStatus = 'In Use',
    Map<String, dynamic>? metadata,
  }) async {
    final effectiveMetadata = metadata ?? const <String, dynamic>{};
    final isHandOver = transactionStatus == 'Hand Over';

    var firestoreWriteFailed = false;

    for (final selected in keys) {
      final selectedStatus = selected.status.trim();
      if (isLockedStatus(selectedStatus)) {
        continue;
      }

      final index = _indexForRecord(selected);
      if (index == -1) {
        continue;
      }

      final purposeValue =
          effectiveMetadata['purpose']?.toString().trim().isNotEmpty == true
          ? effectiveMetadata['purpose'].toString().trim()
          : (_keys[index].purpose.isEmpty
                ? 'Routine access'
                : _keys[index].purpose);
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
      _notifyKeys();

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

      if (_firestoreAvailable) {
        try {
          final target = _keys[index];
          await _saveKey(target);
          await _appendEvent(event);
          final body = _notificationBodyForTakenKey(
            key: _keys[index],
            borrowerName: borrower.name,
            purpose: purposeValue,
            actor: recordedBy,
          );
          await _saveNotification(
            action: isHandOver ? 'Key Handed Over' : 'Key Taken - In Use',
            title: isHandOver ? 'Key Handed Over' : 'Key Taken',
            body: body,
            keyId: _keys[index].keyId,
            category: _keys[index].category,
            recordedBy: recordedBy,
            audience: 'allMembers',
            type: isHandOver ? 'hand_over' : 'take_key',
            extraData: {
              'borrowerName': borrower.name,
              'purpose': purposeValue,
              'level': _normalizeMetadataField(_keys[index].metadata['level']),
              'masterKey': _normalizeMetadataField(_keys[index].metadata['masterKey']),
              'lotKey': _normalizeMetadataField(_keys[index].metadata['lotKey']),
              'rollerLevelNo': _normalizeMetadataField(_keys[index].metadata['rollerLevelNo']),
              'rollerNumber': _normalizeMetadataField(_keys[index].metadata['rollerNumber']),
              'zone': _keys[index].zone,
            },
          );
        } catch (_) {
          firestoreWriteFailed = true;
        }
      } else {
        await _appendEvent(event);
      }
    }

    if (_firestoreAvailable) {
      await refreshKeysFromFirestore();
      if (firestoreWriteFailed) {
        throw Exception(
          'Some keys failed to update in Firestore. Please retry.',
        );
      }
    }
  }

  static Future<void> returnKey(KeyRecord record) async {
    final index = _indexForRecord(record);
    if (index == -1) {
      return;
    }
    // Determine stable id for guarding concurrent returns: prefer docId, fallback to keyId
    final id = (record.docId?.trim().isNotEmpty ?? false)
        ? record.docId!.trim()
        : record.keyId.trim().toUpperCase();

    if (_inFlightReturnKeys.contains(id)) {
      debugPrint('[KeyRepository] returnKey ignored: already in-flight for $id');
      return;
    }

    // If key is already available locally, skip processing (idempotent)
    if (_keys[index].status.trim().toLowerCase() == 'available') {
      debugPrint('[KeyRepository] returnKey ignored: key already available ${record.keyId}');
      return;
    }

    _inFlightReturnKeys.add(id);
    try {
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

      var firestoreWriteFailed = false;
      if (_firestoreAvailable) {
        try {
          await _persistKeyToFirestore(_keys[index]);
          await _saveNotification(
            action: 'Returned',
            title: 'Key Returned',
            body: _notificationBodyForReturnedKey(
              key: _keys[index],
              borrowerName: record.borrowerName,
              purpose: record.purpose,
              actor: resolveActor(null),
            ),
            keyId: _keys[index].keyId,
            category: _keys[index].category,
            recordedBy: resolveActor(null),
            audience: 'allMembers',
            type: 'return_key',
            extraData: {
              'borrowerName': record.borrowerName,
              'purpose': record.purpose,
              'level': _normalizeMetadataField(_keys[index].metadata['level']),
              'masterKey': _normalizeMetadataField(_keys[index].metadata['masterKey']),
              'lotKey': _normalizeMetadataField(_keys[index].metadata['lotKey']),
              'rollerLevelNo': _normalizeMetadataField(_keys[index].metadata['rollerLevelNo']),
              'rollerNumber': _normalizeMetadataField(_keys[index].metadata['rollerNumber']),
              'zone': _keys[index].zone,
              'keyName': _keys[index].keyName,
            },
          );
        } catch (_) {
          firestoreWriteFailed = true;
        }

        await refreshKeysFromFirestore();
        if (firestoreWriteFailed) {
          throw Exception(
            'Failed to update key return in Firestore. Please retry.',
          );
        }
      }

      _notifyKeys();
    } finally {
      _inFlightReturnKeys.remove(id);
    }
  }

  static Future<void> markNoReturn(KeyRecord record) async {
    final index = _indexForRecord(record);
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
      actor: resolveActor(null),
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      try {
        await _saveKey(_keys[index]);
        await _saveNotification(
          action: 'No Return',
          title: 'Key Marked No Return',
          body:
              'From: ${resolveActor(null)}\nKey ${_keys[index].zone}/${_keys[index].keyName} is now marked No Return.',
          keyId: _keys[index].keyId,
          category: _keys[index].category,
          recordedBy: resolveActor(null),
          audience: 'allMembers',
          type: 'key_no_return',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static Future<void> markAtMaintenance(KeyRecord record) async {
    final index = _indexForRecord(record);
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
      actor: resolveActor(null),
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      try {
        await _saveKey(_keys[index]);
        await _saveNotification(
          action: 'At Maintenance',
          title: 'Key Under Maintenance',
          body:
              'From: ${resolveActor(null)}\nKey ${_keys[index].zone}/${_keys[index].keyName} is now under maintenance.',
          keyId: _keys[index].keyId,
          category: _keys[index].category,
          recordedBy: resolveActor(null),
          audience: 'allMembers',
          type: 'at_maintenance',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static Future<void> markLost(KeyRecord record) async {
    await _updateKeyStatus(
      record,
      status: 'Lost',
      action: 'Lost',
      actor: resolveActor(null),
      lose: true,
    );
  }

  static Future<void> markDamaged(KeyRecord record) async {
    await _updateKeyStatus(
      record,
      status: 'Damaged',
      action: 'Damaged',
      actor: resolveActor(null),
    );
  }

  static Future<void> markReplaced(KeyRecord record) async {
    final index = _indexForRecord(record);
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

    final event = EventLog(
      action: 'Replaced',
      keyId: _keys[index].keyId,
      keyName: _keys[index].keyName,
      borrowerName: record.borrowerName,
      icPassport: record.icPassport,
      phoneNumber: record.phoneNumber,
      company: record.company,
      purpose: record.purpose,
      dateTimeTaken: DateTime.now(),
      dateTimeReturned: DateTime.now(),
      status: 'Available',
      lose: false,
      actor: resolveActor(null),
      category: _keys[index].category,
      metadata: record.metadata,
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      try {
        await _saveKey(_keys[index]);
        await _saveNotification(
          action: 'Replaced',
          title: 'Key Replaced',
          body:
              'From: ${resolveActor(null)}\nKey ${_keys[index].zone}/${_keys[index].keyName} has been replaced and is now Available.',
          keyId: _keys[index].keyId,
          category: _keys[index].category,
          recordedBy: resolveActor(null),
          audience: 'allMembers',
          type: 'replaced',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static Future<void> markHandOver(
    KeyRecord record, {
    String actor = '',
  }) async {
    await _updateKeyStatus(
      record,
      status: 'Hand Over',
      action: 'Hand Over',
      actor: resolveActor(actor),
    );
  }

  static Future<void> markHandOverWithDetails(
    KeyRecord record, {
    required String actor,
    required Map<String, dynamic> metadata,
  }) async {
    final index = _indexForRecord(record);
    if (index == -1) {
      return;
    }

    final mergedMetadata = Map<String, dynamic>.from(_keys[index].metadata)
      ..addAll(metadata);

    _keys[index] = _keys[index].copyWith(
      status: 'Hand Over',
      metadata: mergedMetadata,
    );
    final event = EventLog(
      action: 'Hand Over',
      keyId: _keys[index].keyId,
      keyName: _keys[index].keyName,
      borrowerName: _keys[index].borrowerName,
      icPassport: _keys[index].icPassport,
      phoneNumber: _keys[index].phoneNumber,
      company: _keys[index].company,
      purpose: _keys[index].purpose,
      dateTimeTaken: _keys[index].takenAt,
      dateTimeReturned: null,
      status: 'Hand Over',
      lose: false,
      actor: resolveActor(actor),
      category: _keys[index].category,
      metadata: mergedMetadata,
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      try {
        await _saveKey(_keys[index]);
        await _saveNotification(
          action: 'Hand Over',
          title: 'Key Handed Over',
          body:
              'From: ${resolveActor(actor)}\nKey ${_keys[index].zone}/${_keys[index].keyName} is now marked Hand Over.',
          keyId: _keys[index].keyId,
          category: _keys[index].category,
          recordedBy: resolveActor(actor),
          audience: 'allMembers',
          type: 'hand_over',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static Future<void> receiveKeyWithDetails(
    KeyRecord record, {
    required String actor,
    required Map<String, dynamic> metadata,
  }) async {
    final index = _indexForRecord(record);
    if (index == -1) {
      return;
    }

    final mergedMetadata = Map<String, dynamic>.from(_keys[index].metadata)
      ..addAll(metadata);
    final previous = _keys[index];

    _keys[index] = _keys[index].copyWith(
      status: 'Available',
      borrowerName: '',
      icPassport: '',
      phoneNumber: '',
      company: '',
      purpose: '',
      takenAt: DateTime.now(),
      metadata: mergedMetadata,
    );

    final event = EventLog(
      action: 'Receive Key',
      keyId: previous.keyId,
      keyName: previous.keyName,
      borrowerName: previous.borrowerName,
      icPassport: previous.icPassport,
      phoneNumber: previous.phoneNumber,
      company: previous.company,
      purpose: previous.purpose,
      dateTimeTaken: DateTime.now(),
      dateTimeReturned: DateTime.now(),
      status: 'Available',
      lose: false,
      actor: resolveActor(actor),
      category: previous.category,
      metadata: mergedMetadata,
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      try {
        await _saveKey(_keys[index]);
        await _saveNotification(
          action: 'Receive Key',
          title: 'Key Received',
          body:
              'From: ${resolveActor(actor)}\nKey ${previous.zone}/${previous.keyName} has been received and is now Available.',
          keyId: previous.keyId,
          category: previous.category,
          recordedBy: resolveActor(actor),
          audience: 'allMembers',
          type: 'receive_key',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static Future<void> _updateKeyStatus(
    KeyRecord record, {
    required String status,
    required String action,
    required String actor,
    bool lose = false,
  }) async {
    final index = _indexForRecord(record);
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
      actor: resolveActor(actor),
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      try {
        await _saveKey(_keys[index]);
        await _saveNotification(
          action: action,
          title: _notificationTitleForStatus(status, action),
          body: _notificationBodyForStatus(
            status: status,
            keyName: _keys[index].keyName,
            zone: _keys[index].zone,
            actor: resolveActor(actor),
          ),
          keyId: _keys[index].keyId,
          category: _keys[index].category,
          recordedBy: resolveActor(actor),
          audience: 'allMembers',
          type: _notificationTypeForStatus(status, action),
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static String _notificationTitleForStatus(String status, String action) {
    switch (status) {
      case 'Lost':
        return 'Key Lost';
      case 'Damaged':
        return 'Key Damaged';
      case 'Available':
        return 'Key Available';
      case 'In Use':
        return 'Key In Use';
      case 'Hand Over':
        return 'Key Handed Over';
      case 'Not Available':
        return 'Key Not Available';
      default:
        return action;
    }
  }

  static String _notificationBodyForStatus({
    required String status,
    required String keyName,
    required String zone,
    required String actor,
  }) {
    final fromText = actor.isNotEmpty ? 'From: $actor\n' : '';
    switch (status) {
      case 'Lost':
        return actor.isNotEmpty
            ? '${fromText}Marked $zone/$keyName as Lost.'
            : '${fromText}The key $zone/$keyName was marked as Lost.';
      case 'Damaged':
        return actor.isNotEmpty
            ? '${fromText}Marked $zone/$keyName as Damaged.'
            : '${fromText}The key $zone/$keyName was marked as Damaged.';
      case 'Available':
        return '${fromText}Key $zone/$keyName is now Available.';
      case 'In Use':
        return '${fromText}Key $zone/$keyName is now In Use.';
      case 'Hand Over':
        return '${fromText}Key $zone/$keyName is now marked Hand Over.';
      case 'Not Available':
        return '${fromText}Key $zone/$keyName is now marked Not Available.';
      default:
        return '${fromText}Key $zone/$keyName status changed to $status.';
    }
  }

  static String _notificationBodyForTakenKey({
    required KeyRecord key,
    required String borrowerName,
    required String purpose,
    required String actor,
  }) {
    final category = key.category.trim().toLowerCase();
    final level = key.metadata['level']?.toString().trim() ?? '';
    final borrower = borrowerName.trim().isNotEmpty ? borrowerName.trim() : 'Unknown borrower';
    final purposeText = purpose.trim().isNotEmpty ? purpose.trim() : 'Routine access';
    final zoneValue = key.zone.trim().isNotEmpty
        ? key.zone.trim()
        : key.metadata['zone']?.toString().trim() ?? '';

    String keyReference;
    switch (category) {
      case 'zone':
        keyReference = level.isNotEmpty ? '$level / $zoneValue' : zoneValue;
        break;
      case 'master key':
        final masterKey = key.metadata['masterKey']?.toString().trim() ?? '';
        final masterKeyLabel = masterKey.isNotEmpty
            ? 'MASTER KEY $masterKey'
            : key.keyName.trim();
        keyReference = level.isNotEmpty ? '$level / $masterKeyLabel' : masterKeyLabel;
        break;
      case 'lot':
        final lotKey = key.metadata['lotKey']?.toString().trim() ?? '';
        final lotReference = lotKey.isNotEmpty ? lotKey : key.keyName.trim();
        keyReference = level.isNotEmpty ? '$level / $lotReference' : lotReference;
        break;
      case 'roller shutter':
        final rollerNumber = key.metadata['rollerNumber']?.toString().trim() ?? '';
        final rollerReference = rollerNumber.isNotEmpty ? rollerNumber : key.keyName.trim();
        keyReference = level.isNotEmpty ? '$level / $rollerReference' : rollerReference;
        break;
      default:
        final nameValue = key.keyName.trim().isNotEmpty ? key.keyName.trim() : key.keyId.trim();
        keyReference = level.isNotEmpty ? '$level / $nameValue' : nameValue;
        break;
    }

    final fromText = actor.isNotEmpty ? 'From: $actor\n' : '';
    return '${fromText}Key $keyReference has been taken by $borrower.\nPurpose: $purposeText';
  }

  static String _notificationBodyForReturnedKey({
    required KeyRecord key,
    required String borrowerName,
    required String purpose,
    required String actor,
  }) {
    final category = key.category.trim().toLowerCase();
    final level = key.metadata['level']?.toString().trim() ?? '';
    final borrower = borrowerName.trim().isNotEmpty ? borrowerName.trim() : 'Unknown borrower';
    final purposeText = purpose.trim().isNotEmpty ? purpose.trim() : 'Routine access';
    final zoneValue = key.zone.trim().isNotEmpty
        ? key.zone.trim()
        : key.metadata['zone']?.toString().trim() ?? '';

    String keyReference;
    switch (category) {
      case 'zone':
        keyReference = level.isNotEmpty ? '$level / $zoneValue' : zoneValue;
        break;
      case 'master key':
        final masterKey = key.metadata['masterKey']?.toString().trim() ?? '';
        final masterKeyLabel = masterKey.isNotEmpty
            ? 'MASTER KEY $masterKey'
            : key.keyName.trim();
        keyReference = level.isNotEmpty ? '$level / $masterKeyLabel' : masterKeyLabel;
        break;
      case 'lot':
        final lotKey = key.metadata['lotKey']?.toString().trim() ?? '';
        final lotReference = lotKey.isNotEmpty ? lotKey : key.keyName.trim();
        keyReference = level.isNotEmpty ? '$level / $lotReference' : lotReference;
        break;
      case 'roller shutter':
        final rollerNumber = key.metadata['rollerNumber']?.toString().trim() ?? '';
        final rollerReference = rollerNumber.isNotEmpty ? rollerNumber : key.keyName.trim();
        keyReference = level.isNotEmpty ? '$level / $rollerReference' : rollerReference;
        break;
      default:
        final nameValue = key.keyName.trim().isNotEmpty ? key.keyName.trim() : key.keyId.trim();
        keyReference = level.isNotEmpty ? '$level / $nameValue' : nameValue;
        break;
    }

    final fromText = actor.isNotEmpty ? 'From: $actor\n' : '';
    return '${fromText}Key $keyReference has been returned by $borrower.\nPurpose: $purposeText\nStatus: Available';
  }

  static String _normalizeMetadataField(Object? field) {
    if (field == null) {
      return '';
    }
    return field.toString().trim();
  }

  static String _notificationTypeForStatus(String status, String action) {
    switch (status) {
      case 'Lost':
        return 'key_lost';
      case 'Damaged':
        return 'key_damaged';
      case 'Available':
        return 'key_available';
      case 'In Use':
        return 'key_in_use';
      case 'Hand Over':
        return 'hand_over';
      case 'Not Available':
        return 'key_not_available';
      default:
        return action.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    }
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
      actor: resolveActor(null),
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
      docId: _keyDocIdForRecord(
        KeyRecord(
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
        ),
      ),
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

    final existingIndex = _keys.indexWhere(
      (item) => _sameLogicalKey(item, key),
    );
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
      final qtyValue = metadata == null
          ? ''
          : metadata['qty']?.toString().trim() ?? '';
      final qtySuffix = qtyValue.isEmpty ? '' : ' Qty: $qtyValue.';
      try {
        await _saveKey(key);
        await _saveNotification(
          action: normalizedStatus == 'Not Available'
              ? 'New Key Registered - Not Available'
              : 'New Key Registered',
          title: normalizedStatus == 'Not Available'
              ? 'New Key Registered - Not Available'
              : 'New Key Registered',
          body: normalizedStatus == 'Not Available'
              ? 'From: $recordedBy\nKey $keyName registered as Not Available'
              : 'From: $recordedBy\nA new key "$keyName" has been registered.$qtySuffix',
          keyId: key.keyId,
          category: category,
          recordedBy: recordedBy,
          audience: 'allMembers',
          type: normalizedStatus == 'Not Available'
              ? 'register_key_not_available'
              : 'register_key',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
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
      try {
        if (updatedRecord != null) {
          await _saveKey(updatedRecord);
        } else {
          final mergedMetadata = metadata ?? const <String, dynamic>{};
          final transient = KeyRecord(
            keyId: keyId,
            zone: zone,
            keyName: keyName,
            borrowerName: '',
            icPassport: '',
            phoneNumber: '',
            company: '',
            purpose: mergedMetadata['purpose']?.toString() ?? '',
            status: status,
            takenAt: DateTime.now(),
            category: category,
            metadata: mergedMetadata,
          );
          await _keysCollection.doc(_keyDocIdForRecord(transient)).set({
            'keyId': keyId,
            'zone': zone,
            'keyName': keyName,
            'category': category,
            'status': status,
            'purpose': mergedMetadata['purpose']?.toString() ?? '',
            'metadata': mergedMetadata,
            'takenAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await _saveNotification(
          action: 'Key Details Edited',
          title: 'Key Updated',
          body: 'From: $recordedBy\nKey "$keyName" details were updated.',
          keyId: keyId,
          category: category,
          recordedBy: recordedBy,
          audience: 'allMembers',
          type: 'edit_key',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static Future<void> deleteKey(
    KeyRecord record, {
    String recordedBy = '',
  }) async {
    final index = _indexForRecord(record);
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
      actor: resolveActor(recordedBy),
      category: deleted.category,
      metadata: deleted.metadata,
    );
    await _appendEvent(event);

    if (_firestoreAvailable) {
      try {
        await _keysCollection.doc(_keyDocIdForRecord(deleted)).delete();
        await _saveNotification(
          action: 'Key Deleted',
          title: 'Key Deleted',
          body:
              'From: $recordedBy\nKey ${deleted.zone}/${deleted.keyName} was deleted.',
          keyId: deleted.keyId,
          category: deleted.category,
          recordedBy: recordedBy,
          audience: 'allMembers',
          type: 'delete_key',
        );
      } catch (_) {
        // Keep the key update logic intact; skip notification if Firestore write fails.
      }
    }

    _notifyKeys();
  }

  static void _notifyKeys() {
    _keysController.add(List.unmodifiable(_keys));
  }
}
