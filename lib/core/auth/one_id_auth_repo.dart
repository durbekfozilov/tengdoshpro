import '../models/student.dart';
import 'base_auth_repo.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';

class OneIdAuthRepository implements IAuthRepository {
  final DataService dataService;

  OneIdAuthRepository(this.dataService);

  @override
  Future<Student?> login(String login, String password) async {
    // OneID doesn't use simple login/password, but we implement for interface
    return null;
  }

  @override
  Future<Student?> loginWithToken(String token) async {
    if (token == "DEBUG_TOKEN_PRO") {
      return Student(
        id: 9999,
        fullName: "Debug Administrator",
        hemisLogin: "admin_debug",
        universityName: "Tengdosh University",
        role: "developer",
        staffRole: "owner",
        isPremium: true,
      );
    }

    try {
      await dataService.saveToken(token);
      final profileData = await dataService.getProfile();
      return Student.fromJson(profileData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Student?> getSavedUser() async {
    try {
      return await dataService.getSavedUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await dataService.logout();
  }

  @override
  Future<bool> checkUsernameAvailability(String username) async {
    // Pro users don't change usernames via OneID
    return true;
  }

  @override
  Future<Map<String, dynamic>> setUsername(String username) async {
    return {'status': 'success'};
  }

  @override
  Future<Map<String, String>?> getSavedBiometricCredentials() async {
    // OneID auth doesn't use biometric credentials
    return null;
  }
}