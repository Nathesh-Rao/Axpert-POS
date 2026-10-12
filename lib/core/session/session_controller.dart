import 'dart:async';

import 'package:get/get.dart';

import '../security/authenticated_session.dart';
import '../security/authentication_service.dart';
import '../security/authentication_request.dart';
import '../result/result.dart';

enum SessionStatus { restoring, unauthenticated, authenticated }

/// Application-level session state; it contains no credentials or claims.
final class SessionController extends GetxController {
  SessionController({required AuthenticationService authenticationService})
    : _authenticationService = authenticationService;

  final AuthenticationService _authenticationService;
  final Rx<SessionStatus> status = SessionStatus.restoring.obs;
  final Rxn<AuthenticatedSession> session = Rxn<AuthenticatedSession>();

  @override
  void onInit() {
    super.onInit();
    unawaited(restoreSession());
  }

  Future<void> restoreSession() async {
    status.value = SessionStatus.restoring;
    final result = await _authenticationService.restoreSession();
    result.fold(onSuccess: _setSession, onFailure: (_) => _setSession(null));
  }

  Future<Result<AuthenticatedSession>> authenticate(
    AuthenticationRequest request,
  ) async {
    final result = await _authenticationService.authenticate(request);
    result.fold<void>(
      onSuccess: (value) => _setSession(value),
      onFailure: (_) {},
    );
    return result;
  }

  Future<Result<void>> signOut() async {
    final result = await _authenticationService.signOut();
    result.fold<void>(onSuccess: (_) => _setSession(null), onFailure: (_) {});
    return result;
  }

  void _setSession(AuthenticatedSession? value) {
    session.value = value;
    status.value = value == null
        ? SessionStatus.unauthenticated
        : SessionStatus.authenticated;
  }
}
