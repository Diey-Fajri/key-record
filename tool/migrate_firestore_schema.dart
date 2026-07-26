import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:key_record/firebase_options.dart';
import 'package:key_record/services/key_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
    rethrow;
  }

  final keyUpdates = await KeyRecordRepository.migrateExistingKeysToNewFirestoreSchema(
    dryRun: false,
  );
  final eventUpdates = await KeyRecordRepository.migrateExistingEventLogsToNewFirestoreSchema(
    dryRun: false,
  );

  debugPrint('Firestore migration completed. Updated keys: $keyUpdates');
  debugPrint('Firestore migration completed. Updated event logs: $eventUpdates');
}
