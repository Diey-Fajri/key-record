import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

class AppNotificationMessage {
  const AppNotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
}

typedef AppNotificationCallback = FutureOr<void> Function(AppNotificationMessage message);

class AppNotificationService {
  AppNotificationService._();

  static AppNotificationCallback? onNotificationReceived;

  static final Set<String> _seenNotificationIds = <String>{};

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  static bool _initialized = false;
  static bool _readyToShow = false;
  static bool _dialogVisible = false;

  static bool hasSeenNotification(String notificationId) {
    return _seenNotificationIds.contains(notificationId);
  }

  static void markNotificationAsSeen(String notificationId) {
    _seenNotificationIds.add(notificationId);
  }

  static Future<void> start() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    if (!Firebase.apps.isNotEmpty) {
      return;
    }

    if (AuthService.activeUser.isEmpty) {
      return;
    }

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('audience', isEqualTo: 'allMembers')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen(_handleSnapshot, onError: (error) {
      debugPrint('Notification listener error: $error');
    });
  }

  static Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    _readyToShow = false;
    _dialogVisible = false;
  }

  static Future<void> _handleSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) async {
    if (!_readyToShow) {
      _readyToShow = true;
      return;
    }

    final context = _rootContext();
    if (context == null) {
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) {
        continue;
      }

      final doc = change.doc;
      if (doc.metadata.hasPendingWrites) {
        continue;
      }

      try {
        final data = doc.data();
        if (data == null) {
          continue;
        }

        final recordedBy = data['recordedBy']?.toString().trim() ?? '';
        if (recordedBy.isNotEmpty &&
            AuthService.activeUser.isNotEmpty &&
            recordedBy == AuthService.activeUser) {
          continue;
        }

        final rawReadBy = data['readBy'];
        final readBy = <String>[];
        if (rawReadBy is List) {
          for (final item in rawReadBy) {
            if (item is String) {
              readBy.add(item);
            }
          }
        }

        if (readBy.contains(AuthService.activeUser)) {
          continue;
        }

        final message = AppNotificationMessage(
          id: doc.id,
          title: data['title']?.toString() ?? 'Notification',
          body: data['body']?.toString() ?? '',
          type: data['type']?.toString() ?? '',
          data: Map<String, dynamic>.from(data),
        );

        final callback = onNotificationReceived;
        if (callback != null) {
          unawaited(Future<void>.sync(() => callback(message)));
        }

        await _showPopup(
          context: context,
          title: message.title,
          body: message.body,
          docId: doc.id,
        );
        markNotificationAsSeen(doc.id);
      } catch (error) {
        debugPrint('Notification parse error: $error');
      }
    }
  }

  static BuildContext? _rootContext() {
    return appNavigatorKey.currentState?.overlay?.context;
  }

  static Future<void> _showPopup({
    required BuildContext context,
    required String title,
    required String body,
    required String docId,
  }) async {
    if (_dialogVisible) {
      return;
    }

    _dialogVisible = true;
    try {
      if (!context.mounted) {
        return;
      }

      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messengerState = appScaffoldMessengerKey.currentState;
        if (messengerState != null) {
          messengerState.hideCurrentSnackBar();
          messengerState.showSnackBar(
            SnackBar(
              content: Text('$title\n$body'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future;

      if (AuthService.activeUser.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').doc(docId).set(
          {
            'readBy': FieldValue.arrayUnion([AuthService.activeUser]),
          },
          SetOptions(merge: true),
        );
      }
    } catch (error) {
      debugPrint('Notification popup error: $error');
    } finally {
      _dialogVisible = false;
    }
  }
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();