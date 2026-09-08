import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  test('chiusa e riaperta l\'app resta loggato (sessione persistente)', () async {
    final session = InMemoryAuthSession();
    final firstLaunch = FakeAuthRepository(session: session);

    await firstLaunch.signIn(
      email: 'giovanna@amiciperlacoda.it',
      password: 'corretta',
    );
    expect(firstLaunch.currentUser?.email, 'giovanna@amiciperlacoda.it');

    final relaunch = FakeAuthRepository(session: session);
    expect(relaunch.currentUser?.email, 'giovanna@amiciperlacoda.it');
  });
}
