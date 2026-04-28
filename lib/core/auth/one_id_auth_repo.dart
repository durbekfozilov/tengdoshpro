import '../network/data_service.dart';
import '../models/student.dart';
import 'base_auth_repo.dart';

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
    try {
      // 1. Save token
      await dataService.saveToken(token);
      
      // 2. Fetch profile
      final profileData = await dataService.getProfile();
      return Student.fromJson(profileData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Student?> getSavedUser() async {
    try {
      final profileData = await dataService.getProfile();
      return Student.fromJson(profileData);
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
    // Pro users don't usually change usernames here
    return true;
  }

  @override
  Future<Map<String, dynamic>> setUsername(String username) async {
    return {'status': 'success'};
  }
}
