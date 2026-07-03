import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/auth_service.dart';

void main() {
  test('6-digit passwords pass validation', () {
    expect(AuthService.isPasswordStrong('123456'), isTrue);
  });

  test('non-6-digit passwords fail validation', () {
    expect(AuthService.isPasswordStrong('12345'), isFalse);
  });

  test('invalid auth errors should prompt for setup', () {
    expect(AuthService.shouldPromptForSetupAfterAuthError('wrong-password'), isTrue);
    expect(AuthService.shouldPromptForSetupAfterAuthError('user-not-found'), isTrue);
    expect(AuthService.shouldPromptForSetupAfterAuthError('network-request-failed'), isTrue);
    expect(AuthService.shouldPromptForSetupAfterAuthError('email-already-in-use'), isFalse);
  });

  test('sign-in errors distinguish existing account from missing account', () {
    expect(AuthService.shouldCreateAccountAfterSignInError('user-not-found'), isTrue);
    expect(AuthService.shouldCreateAccountAfterSignInError('invalid-credential'), isFalse);
    expect(AuthService.shouldCreateAccountAfterSignInError('wrong-password'), isFalse);
    expect(AuthService.shouldCreateAccountAfterSignInError('network-request-failed'), isFalse);
  });
}
