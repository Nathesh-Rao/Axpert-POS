import '../result/result.dart';
import 'authenticated_session.dart';
import 'authentication_request.dart';

/// Application-level authentication operations, independent of HTTP details.
abstract interface class AuthenticationService {
  Future<Result<AuthenticatedSession?>> restoreSession();

  Future<Result<AuthenticatedSession>> authenticate(
    AuthenticationRequest request,
  );

  Future<Result<void>> signOut();
}
