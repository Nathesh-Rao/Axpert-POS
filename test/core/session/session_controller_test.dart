import 'package:pos_application/core/session/session_controller.dart';
import 'package:pos_application/core/result/result.dart';
import 'package:pos_application/core/security/authenticated_session.dart';
import 'package:pos_application/core/security/authentication_request.dart';
import 'package:pos_application/core/security/authentication_service.dart';
import 'package:pos_application/core/security/unconfigured_authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  test(
    'unconfigured service restores as unauthenticated and refuses auth',
    () async {
      const service = UnconfiguredAuthenticationService();
      final restored = await service.restoreSession();
      expect(restored, isA<ResultSuccess<AuthenticatedSession?>>());
      expect((restored as ResultSuccess<AuthenticatedSession?>).value, isNull);

      final attempted = await service.authenticate(_Request());
      expect(attempted, isA<ResultFailure<AuthenticatedSession>>());
    },
  );

  test(
    'controller restores, authenticates, then clears session on sign out',
    () async {
      final service = _TestAuthenticationService();
      final controller = SessionController(authenticationService: service);
      Get.put<SessionController>(controller);
      await controller.restoreSession();
      expect(controller.status.value, SessionStatus.unauthenticated);

      final authenticated = await controller.authenticate(_Request());
      expect(authenticated, isA<ResultSuccess<AuthenticatedSession>>());
      expect(controller.status.value, SessionStatus.authenticated);

      await controller.signOut();
      expect(controller.status.value, SessionStatus.unauthenticated);
      expect(controller.session.value, isNull);
    },
  );
}

final class _Request implements AuthenticationRequest {}

final class _TestAuthenticationService implements AuthenticationService {
  static const _session = AuthenticatedSession();

  @override
  Future<Result<AuthenticatedSession>> authenticate(
    AuthenticationRequest request,
  ) async => const Result.success(_session);

  @override
  Future<Result<AuthenticatedSession?>> restoreSession() async =>
      const Result.success(null);

  @override
  Future<Result<void>> signOut() async => const Result.success(null);
}
