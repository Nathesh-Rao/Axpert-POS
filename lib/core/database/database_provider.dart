import 'axpert_database.dart';

/// Application-facing access point for the local Drift database.
abstract interface class DatabaseProvider {
  Future<AxpertDatabase> open();

  Future<void> close();
}
