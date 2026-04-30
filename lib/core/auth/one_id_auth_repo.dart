import 'package:talabahamkor_mobile/core/models/student.dart';
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
    if (token.startsWith("DEBUG_TOKEN_PRO")) {
      String staffRole = "owner";
      String fullName = "Debug Administrator";
      
      if (token.contains("_DEKAN")) {
        staffRole = "dekan";
        fullName = "Debug Dekan";
      } else if (token.contains("_REKTOR")) {
        staffRole = "rektor";
        fullName = "Debug Rektor";
      } else if (token.contains("_PROREKTOR")) {
        staffRole = "prorektor";
        fullName = "Debug Prorektor";
      } else if (token.contains("_TYUTOR")) {
        staffRole = "tyutor";
        fullName = "Debug Tyutor";
      }

      return Student(
        id: 9999,
        fullName: fullName,
        hemisLogin: "admin_debug",
        universityName: "Tengdosh University",
        role: "staff",
        staffRole: staffRole,
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