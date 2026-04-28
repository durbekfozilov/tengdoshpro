import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final Dio dio;
  static String _baseUrl = "https://central.tengdosh.uz";

  ApiClient(this.dio) {
    final authService = AuthService();
    
    dio.options.baseUrl = _baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = _baseUrl;
        
        // Centralized Token Injection
        final token = await authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['X-Api-Key'] = ApiConstants.apiToken;
        
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          debugPrint("GLOBAL AUTH ERROR: Session expired or invalid token.");
        }
        return handler.next(e);
      },
    ));
  }

  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    dio.options.baseUrl = _baseUrl;
    debugPrint("ApiClient: BaseURL updated to $newBaseUrl");
  }

  String get baseUrl => _baseUrl;
}
