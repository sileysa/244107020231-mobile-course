import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/auth/domain/entities/auth_session.dart';
import 'package:week7_clean_architecture/features/auth/domain/repositories/auth_repository.dart';
import 'package:week7_clean_architecture/features/auth/domain/usecases/login.dart';

class FakeAuthRepository implements AuthRepository {
  AuthSession? session;
  int calls = 0;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    calls++;
    session = AuthSession(email: email);
    return (session: session, failure: null);
  }
}

void main() {
  test('Login mendelegasikan kredensial valid ke repository', () async {
    final repository = FakeAuthRepository();

    final result = await Login(repository)
        .call(email: 'student@example.test', password: 'secret1');

    expect(result.failure, isNull);
    expect(result.session?.email, 'student@example.test');
    expect(repository.calls, 1);
  });

  test(
    'Login menolak kredensial tidak valid tanpa memanggil repository',
    () async {
      final repository = FakeAuthRepository();

      final result = await Login(repository)
          .call(email: 'invalid', password: '123');

      expect(result.session, isNull);
      expect(result.failure, isA<AuthenticationFailure>());
      expect(result.failure?.message, 'Email atau kata sandi tidak valid.');
      expect(repository.calls, 0);
    },
  );
}
