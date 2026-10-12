import 'package:flutter/foundation.dart';

/// One infrastructure step that failed during start-up.
class StartupFailure {
  const StartupFailure(this.stage, this.error, this.stackTrace);

  final String stage;
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => '$stage: $error';
}

/// Failures the app survived while starting (for example the local database
/// could not be opened). The POS keeps running without a visible message
/// (DEC-119); tests and logs read the list, and a later screen can show it.
class StartupDiagnostics {
  final List<StartupFailure> failures = <StartupFailure>[];

  bool get hasFailures => failures.isNotEmpty;

  void record(String stage, Object error, StackTrace stackTrace) {
    failures.add(StartupFailure(stage, error, stackTrace));
    if (kDebugMode) debugPrint('Start-up failure in $stage: $error');
  }
}
