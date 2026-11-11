import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim();
    if (!normalizedEmail.contains('@') || password.length < 6) {
      return Future.value((
        session: null,
        failure: const AuthenticationFailure(
          'Email atau kata sandi tidak valid.',
        ),
      ));
    }

    return _repository.login(email: normalizedEmail, password: password);
  }
}
