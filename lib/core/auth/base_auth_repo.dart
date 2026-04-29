import '../models/student.dart';

abstract class IAuthRepository {
  Future<Student?> login(String login, String password);
  Future<Student?> loginWithToken(String token);
  Future<void> logout();
  Future<Student?> getSavedUser();
  Future<bool> checkUsernameAvailability(String username);
  Future<Map<String, dynamic>> setUsername(String username);

  // Optional: returns saved biometric credentials if supported
  Future<Map<String, String>?> getSavedBiometricCredentials() async => null;

}