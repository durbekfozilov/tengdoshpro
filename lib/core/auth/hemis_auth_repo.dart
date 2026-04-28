import 'base_auth_repo.dart';
import '../models/student.dart';
import '../services/auth_service.dart';

class HemisAuthRepository implements IAuthRepository {
  final AuthService _authService = AuthService();

  @override
  Future<Student?> login(String login, String password) async {
    return await _authService.login(login, password);
  }

  @override
  Future<Student?> loginWithToken(String token) async {
    return await _authService.loginWithOAuthToken(token);
  }

  @override
  Future<Student?> getSavedUser() async {
    return await _authService.getSavedUser();
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  Future<bool> checkUsernameAvailability(String username) async {
    return await _authService.checkUsernameAvailability(username);
  }

  @override
  Future<Map<String, dynamic>> setUsername(String username) async {
    return await _authService.setUsername(username);
  }
}
