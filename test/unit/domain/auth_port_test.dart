import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/domain/ports/auth_port.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('FakeAuthPort', () {
    late FakeAuthPort authPort;

    setUp(() {
      authPort = FakeAuthPort();
    });

    test('currentUser is null by default', () {
      expect(authPort.currentUser, isNull);
    });

    test('signInWithEmail sets currentUser', () async {
      final user =
          await authPort.signInWithEmail('test@example.com', 'password');
      expect(user.uid, 'fake-uid');
      expect(user.email, 'test@example.com');
      expect(authPort.currentUser, isNotNull);
      expect(authPort.currentUser!.email, 'test@example.com');
    });

    test('signUpWithEmail sets currentUser', () async {
      final user =
          await authPort.signUpWithEmail('new@example.com', 'password');
      expect(user.uid, 'fake-uid');
      expect(user.email, 'new@example.com');
      expect(authPort.currentUser, isNotNull);
    });

    test('signInWithGoogle sets currentUser', () async {
      final user = await authPort.signInWithGoogle();
      expect(user.uid, 'google-uid');
      expect(user.email, 'test@gmail.com');
      expect(authPort.currentUser, isNotNull);
    });

    test('signOut clears currentUser', () async {
      await authPort.signInWithEmail('test@example.com', 'password');
      expect(authPort.currentUser, isNotNull);

      await authPort.signOut();
      expect(authPort.currentUser, isNull);
    });

    test('authStateChanges emits current user', () async {
      authPort.simulatedUser = const AuthUser(uid: 'uid1', email: 'a@b.com');
      final user = await authPort.authStateChanges.first;
      expect(user, isNotNull);
      expect(user!.uid, 'uid1');
    });
  });
}
