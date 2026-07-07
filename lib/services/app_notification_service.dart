import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class AppNotificationService {
  AppNotificationService._();

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  static bool _initialized = false;
  static bool _readyToShow = false;
  static bool _dialogVisible = false;
  static SharedPreferences? _prefs;

  static Future<void> start() async {
    if (_initialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();
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
      final data = doc.data();
      if (data == null) {
        continue;
      }

      final readBy = (data['readBy'] as List<dynamic>? ?? const []).cast<String>();
      if (readBy.contains(AuthService.activeUser)) {
        continue;
      }

      await _showPopup(
        context: context,
        title: data['title'] as String? ?? 'Notification',
        body: data['body'] as String? ?? '',
        docId: doc.id,
      );
    }
  }

  static BuildContext? _rootContext() {
    return appNavigatorKey.currentContext;
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          return;
        }

        try {
          await showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(title),
                content: Text(body),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        } finally {
          if (!completer.isCompleted) {
            completer.complete();
          }
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