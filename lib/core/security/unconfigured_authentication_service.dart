import '../errors/app_failure.dart';
import '../result/result.dart';
import 'authenticated_session.dart';
import 'authentication_request.dart';
import 'authentication_service.dart';

/// Safe development adapter used until an approved backend auth contract exists.
final class UnconfiguredAuthenticationService implements AuthenticationService {
  const UnconfiguredAuthenticationService();

  @override
  Future<Result<AuthenticatedSession>> authenticate(
    AuthenticationRequest request,
  ) async => const Result.failure(
    UnexpectedFailure(message: 'Authentication is not configured.'),
  );

  @override
  Future<Result<AuthenticatedSession?>> restoreSession() async =>
      const Result.success(null);

  @override
  Future<Result<void>> signOut() async => const Result.success(null);
}
