import '../models/student.dart';
import 'base_auth_repo.dart';
import '../network/data_service.dart';

class OneIdAuthRepository implements IAuthRepository {
  final DataService dataService;

  OneIdAuthRepository(this.dataService);

  @override
  Future<Student?> getSavedUser() async {
    // Pro staff are technically stored as Student models for compatibility
    return await dataService.getProfile();
  }

  @override
  Future<Student?> login(String login, String password) async {
    // OneID doesn't use login/password directly in the app
    return null;
  }

  @override
  Future<Student?> loginWithToken(String code) async {
    try {
      // Exchange OneID code for a session and university_prefix
      final response = await dataService.authPost('/auth/one-id/callback', body: {'code': code});
      
      if (response.statusCode == 200) {
        final data = response.data;
        final prefix = data['university_prefix'];
        final token = data['token'];

        // Save token
        await dataService.saveToken(token);

        // Crucial: Switch the API to the specific university server
        dataService.updateUniversityServer(prefix);

        // Fetch and return profile
        return await dataService.getProfile();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await dataService.logout();
  }
}
