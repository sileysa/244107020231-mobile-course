import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Monitoring {
  /// Event Analytics non-sensitif untuk bukti monitoring.
  static Future<void> logBetaFeedbackSent() async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'beta_feedback_sent',
      parameters: {'screen_name': 'home'},
    );
  }

  /// Error non-fatal buatan untuk menguji Crashlytics.
  static Future<void> recordTestNonFatal() async {
    await FirebaseCrashlytics.instance.recordError(
      Exception('Test non-fatal error week14'),
      StackTrace.current,
      reason: 'Uji Crashlytics (non-fatal)',
      fatal: false,
    );
  }

    /// HANYA untuk uji: memaksa crash fatal agar muncul di Crashlytics.
  static void forceTestCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}