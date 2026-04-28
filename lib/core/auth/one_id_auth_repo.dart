import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'base_auth_repo.dart';
import '../network/api_client.dart';
import '../models/student.dart';
import '../services/auth_service.dart';

class OneIdAuthRepository implements IAuthRepository {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  @override
  Future<Student?> loginWithToken(String code) async {
    try {
      debugPrint("OneIdAuthRepo: Initiating OAuth2 exchange with authorization_code...");
      
      // 1. Exchange authorization_code for JWT and University Prefix through Central API
      final response = await _dio.post(
        "https://central.tengdosh.uz/api/auth/one-id/exchange",
        data: {"code": code},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final String prefix = data['university_prefix']; // e.g., 'tuit', 'nuu'
        final String token = data['token'];
        final userData = data['user'];

        // 2. IMMEDIATE RE-ROUTING: Switch ApiClient to the university-specific server
        final universityUrl = "https://$prefix.tengdosh.uz";
        ApiClient.setBaseUrl(universityUrl);
        debugPrint("OneIdAuthRepo: Successfully re-routed to $universityUrl");

        // 3. Persistent Storage
        await _authService.saveToken(token);
        await _authService.saveProfileManually(userData);

        return Student.fromJson(userData);
      }
    } catch (e) {
      debugPrint("OneIdAuthRepo: Exchange failed: $e");
      rethrow;
    }
    return null;
  }

  @override
  Future<Student?> login(String login, String password) async {
    throw UnimplementedError("Staff MUST use OneID authentication.");
  }

  @override
  Future<Student?> getSavedUser() async {
    return await _authService.getSavedUser();
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
    ApiClient.setBaseUrl("https://central.tengdosh.uz");
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
