import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http; // Removed by cleanup
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart' as dio;
import 'api_client.dart';
import '../services/auth_service.dart';
import '../services/local_database_service.dart';
import '../constants/api_constants.dart';
import '../../features/accommodation/models/accommodation_listing.dart';
import '../models/attendance.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../../features/social/models/social_activity.dart';
import '../../features/home/models/announcement_model.dart';
import '../../features/home/models/banner_model.dart';
import '../../features/academic/models/survey_models.dart';

class DataService {
  final ApiClient _apiClient;
  final AuthService _authService = AuthService();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  
  DataService(this._apiClient);

  // Centralized Callback for auth errors
  static Function(String)? onAuthError;

  // Refactored GET using Dio
  Future<dio.Response> _get(String url, {Duration? timeout}) async {
    try {
      return await _apiClient.dio.get(
        url,
        options: dio.Options(receiveTimeout: timeout),
      );
    } on dio.DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // Refactored POST using Dio
  Future<dio.Response> _post(String url, {Object? body, Duration? timeout}) async {
    try {
      return await _apiClient.dio.post(
        url,
        data: body,
        options: dio.Options(sendTimeout: timeout),
      );
    } on dio.DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // Refactored PUT using Dio
  Future<dio.Response> _put(String url, {Object? body}) async {
    try {
      return await _apiClient.dio.put(url, data: body);
    } on dio.DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // Refactored DELETE using Dio
  Future<dio.Response> _delete(String url) async {
    try {
      return await _apiClient.dio.delete(url);
    } on dio.DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // Refactored PATCH using Dio
  Future<dio.Response> _patch(String url, {Object? body}) async {
    try {
      return await _apiClient.dio.patch(url, data: body);
    } on dio.DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(dio.DioException e) {
    if (e.response?.statusCode == 401) {
      debugPrint("DataService: 401 Unauthorized detected.");
      onAuthError?.call("Session expired");
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'X-Api-Key': ApiConstants.apiToken,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Public Accessors for Management Services
  Future<dio.Response> authGet(String url) => _get(url);
  Future<dio.Response> authPost(String url, {Object? body}) => _post(url, body: body);




  // 1. Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _get(ApiConstants.profile);

    if (response.statusCode == 200) {
      final data = response.data;
      final profileData = data['data'] ?? data;
      // [NEW] Save to cache so loadUser works offline
      await _authService.saveProfileManually(profileData);
      return profileData;
    } else if (response.statusCode == 403) {
      // Premium revoked/expired
      throw Exception("PREMIUM_REQUIRED");
    }
    throw Exception('Failed to load profile');
  }

  // 26. Upload Avatar
    Future<String?> uploadAvatar(File imageFile) async {
    try {
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _post('${ApiConstants.backendUrl}/student/image', body: formData);

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data']['image_url'];
        } else {
          throw Exception(body['message'] ?? "Server xatosi");
        }
      }
      throw Exception("Server xatosi: ${response.statusCode}");
    } catch (e) {
      debugPrint("DataService: Error uploading avatar: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getStudentPerformance({String? semesterId}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      String url = '${ApiConstants.backendUrl}/student/performance';
      if (semesterId != null && semesterId.isNotEmpty) {
        url += '?semester_id=$semesterId';
      }

      final response = await _get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          if (data['data'] is List) {
             return data['data'] as List<dynamic>;
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint("Get Student Performance Error: $e");
      return [];
    }
  }

  // 2. Get Dashboard Stats (Via Backend Proxy for Real Data)
  Future<Map<String, dynamic>> getDashboardStats({bool refresh = false, String? semester}) async {
    final student = await _authService.getSavedUser();
    final studentId = student?.id ?? 0;

    // 1. Skip Local Cache - Always Fetch from API (User Request)
    // if (!refresh) { ... }

    // 2. Fetch from API
    return await _backgroundRefreshDashboard(studentId, refresh: refresh);
  }

  Future<Map<String, dynamic>> _backgroundRefreshDashboard(int studentId, {bool refresh = false, String? semester}) async {
    try {
      String url = ApiConstants.dashboard;
      if (refresh) {
        url += (url.contains('?') ? '&' : '?') + 'refresh=true';
      }
      if (studentId > 0 && semester != null) {
         // Note: Backend dashboard might not support filtering yet, 
         // but we adding param structure for future or if we modify backend
      }
      
      final response = await _get(url, timeout: const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = response.data;
        final result = {
          "gpa": double.tryParse(data['gpa']?.toString() ?? "0") ?? 0.0,
          "missed_hours": data['missed_hours'] ?? 0,
          "missed_hours_excused": data['missed_hours_excused'] ?? 0,
          "missed_hours_unexcused": data['missed_hours_unexcused'] ?? 0,
          "activities_count": data['activities_count'] ?? 0,
          "clubs_count": data['clubs_count'] ?? 0,
          "activities_approved_count": data['activities_approved_count'] ?? 0,
          "has_active_election": data['has_active_election'] ?? false,
          "active_election_id": data['active_election_id'],
          "has_active_rating": data['has_active_rating'] ?? false,
          "active_rating_roles": data['active_rating_roles'] ?? [],
          "expires_at": data['expires_at'],
          "active_rating_id": data['active_rating_id'],
          "active_rating_title": data['active_rating_title'],
          "active_rating_questions": data['active_rating_questions'],
          "has_voted": data['has_voted'] ?? false,
        };

        // Update Local DB (Non-blocking or at least non-failing for UI)
        try {
          await _dbService.saveCache('dashboard', studentId, result);
        } catch (e) {
          debugPrint("Warning: Failed to cache dashboard: $e"); // [FIXED]
        }
        
        return result; // RETURN LIVE DATA
      }
    } catch (e) {
      debugPrint("Dashboard Sync Error: $e"); // [FIXED]
    }



    // FALLBACK: Try to load from cache if API failed
    try {
      final cached = await _dbService.getCache('dashboard', studentId);
      if (cached != null) {
         return Map<String, dynamic>.from(cached);
      }
    } catch (_) {}

    return {
      "gpa": 0.0,
      "missed_hours": 0,
      "missed_hours_excused": 0, 
      "missed_hours_unexcused": 0,
      "activities_count": 0,
      "clubs_count": 0,
      "has_active_election": false
    };
  }

  // Management Dashboard
  Future<Map<String, dynamic>> getManagementDashboard({bool refresh = false}) async {
    try {
      String url = ApiConstants.managementDashboard;
      if (refresh) {
        url += (url.contains('?') ? '&' : '?') + 'refresh=true';
      }
      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management dashboard: $e");
    }
    return {};
  }

  Future<bool> getManagementRatingStatus() async {
    try {
      final response = await _get(ApiConstants.managementRatingStatus);
      if (response.statusCode == 200) {
        final body = response.data;
        return body['is_active'] ?? false;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching rating status: $e");
    }
    return false;
  }

  Future<Map<String, dynamic>> toggleRatingActivation(String roleType, bool isActive) async {
    try {
      final response = await _post(
        ApiConstants.managementRatingActivate,
        body: {'role_type': roleType, 'is_active': isActive},
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        try {
          final body = response.data;
          return {
            'success': false, 
            'message': body['message'] ?? body['detail'] ?? 'Xato: ${response.statusCode}'
          };
        } catch (_) {
          return {'success': false, 'message': 'Server xatosi: ${response.statusCode}'};
        }
      }
    } catch (e) {
      debugPrint("DataService: Error toggling rating activation: $e");
      return {'success': false, 'message': 'Ulanishda xatolik: $e'};
    }
  }

  Future<Map<String, dynamic>> createManagementSurvey(Map<String, dynamic> surveyData) async {
    try {
      final response = await _post(
        ApiConstants.managementRatingActivate,
        body: surveyData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        try {
          final body = response.data;
          if (response.statusCode == 422) {
            return {
              'success': false, 
              'message': 'Validation Xatosi: ${body['errors'] ?? body['message'] ?? body.toString()}'
            };
          }
          return {'success': false, 'message': body['message'] ?? 'Xato: ${response.statusCode}'};
        } catch (_) {
          return {'success': false, 'message': 'Server xatosi: ${response.statusCode}'};
        }
      }
    } catch (e) {
      debugPrint("DataService: Error creating management survey: $e");
      return {'success': false, 'message': 'Ulanishda xatolik: $e'};
    }
  }

  Future<Map<String, dynamic>> getManagementActiveSurvey() async {
    try {
      final response = await _get(ApiConstants.managementRatingActiveSurvey);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching active survey: $e");
    }
    return {};
  }

  Future<Map<String, dynamic>> updateManagementSurvey(int surveyId, Map<String, dynamic> surveyData) async {
    try {
      surveyData['id'] = surveyId;
      final response = await _post(
        ApiConstants.managementRatingUpdate,
        body: surveyData,
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        try {
          final body = response.data;
          if (response.statusCode == 422) {
            return {
              'success': false, 
              'message': 'Validation Xatosi: ${body['errors'] ?? body['message'] ?? body.toString()}'
            };
          }
          return {'success': false, 'message': body['message'] ?? 'Xato: ${response.statusCode}'};
        } catch (_) {
          return {'success': false, 'message': 'Server xatosi: ${response.statusCode}'};
        }
      }
    } catch (e) {
      debugPrint("DataService: Error updating management survey: $e");
      return {'success': false, 'message': 'Ulanishda xatolik: $e'};
    }
  }

  Future<List<dynamic>> getManagementSurveys() async {
    try {
      final response = await _get(ApiConstants.managementRatingList);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management surveys: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> getSurveyAnalyticsDetail(int surveyId) async {
    try {
      final response = await _get('${ApiConstants.managementRatingStatsDetail}/$surveyId');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching survey analytics detail: $e");
    }
    return {};
  }

  Future<List<dynamic>> getManagementRatingStats() async {
    try {
      final response = await _get(ApiConstants.managementRatingStats);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management rating stats: $e");
    }
    return [];
  }

  // QR Attendance
  Future<Map<String, dynamic>> markQrAttendance(String qrCode) async {
    try {
      final response = await _post(
        '${ApiConstants.backendUrl}/student/attendance/qr-scan',
        body: {'qr_code': qrCode},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'message': 'HTTP xatolik: ${response.statusCode}'};
    } catch (e) {
      debugPrint("DataService: Error marking QR attendance: $e");
      return {'success': false, 'message': 'Ulanishda xatolik: $e'};
    }
  }

  Future<List<dynamic>> getManagementFaculties() async {
    try {
      final response = await _get(ApiConstants.managementFaculties);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management faculties: $e");
    }
    return [];
  }

  Future<List<dynamic>> getManagementLevels(int facultyId) async {
    try {
      final response = await _get("${ApiConstants.managementFaculties}/$facultyId/levels");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management levels: $e");
    }
    return [];
  }

  Future<List<dynamic>> getManagementGroupStudents(String groupNumber) async {
    try {
      final response = await _get("${ApiConstants.managementGroups}/$groupNumber/students");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management group students: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> searchStudents({
    String? query,
    int? facultyId,
    String? educationType,
    String? educationForm,
    String? levelName,
    String? specialtyName,
    String? groupNumber,
  }) async {
    try {
      final queryParams = <String>[];
      if (query != null && query.isNotEmpty) queryParams.add("query=${Uri.encodeComponent(query)}");
      if (facultyId != null) queryParams.add("faculty_id=$facultyId");
      if (educationType != null) queryParams.add("education_type=${Uri.encodeComponent(educationType)}");
      if (educationForm != null) queryParams.add("education_form=${Uri.encodeComponent(educationForm)}");
      if (levelName != null) queryParams.add("level_name=${Uri.encodeComponent(levelName)}");
      if (specialtyName != null) queryParams.add("specialty_name=${Uri.encodeComponent(specialtyName)}");
      if (groupNumber != null) queryParams.add("group_number=${Uri.encodeComponent(groupNumber)}");

      String url = "${ApiConstants.managementStudents}/search";
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body;
      }
    } catch (e) {
      debugPrint("DataService: Error searching students: $e");
    }
    return {"success": false, "data": [], "total_count": 0, "app_users_count": 0};
  }

  Future<List<dynamic>> searchStaff({
    String? query,
    int? facultyId,
    String? role,
  }) async {
    try {
      final queryParams = <String>[];
      if (query != null && query.isNotEmpty) queryParams.add("query=${Uri.encodeComponent(query)}");
      if (facultyId != null) queryParams.add("faculty_id=$facultyId");
      if (role != null) queryParams.add("role=${Uri.encodeComponent(role)}");

      String url = "${ApiConstants.managementStaff}/search";
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error searching staff: $e");
    }
    return [];
  }

  Future<List<dynamic>> getManagementSpecialties({int? facultyId, String? educationType}) async {
    try {
      String url = "${ApiConstants.backendUrl}/management/specialties";
      final queryParams = <String>[];
      if (facultyId != null) queryParams.add("faculty_id=$facultyId");
      if (educationType != null) queryParams.add("education_type=${Uri.encodeComponent(educationType)}");
      
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }
      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management specialties: $e");
    }
    return [];
  }

  Future<List<dynamic>> getManagementGroups({
    int? facultyId, 
    String? levelName,
    String? educationType,
    String? educationForm,
    String? specialtyName,
  }) async {
    try {
      String url = "${ApiConstants.backendUrl}/management/groups";
      final queryParams = <String>[];
      if (facultyId != null) queryParams.add("faculty_id=$facultyId");
      if (levelName != null) queryParams.add("level_name=${Uri.encodeComponent(levelName)}");
      if (educationType != null) queryParams.add("education_type=${Uri.encodeComponent(educationType)}");
      if (educationForm != null) queryParams.add("education_form=${Uri.encodeComponent(educationForm)}");
      if (specialtyName != null) queryParams.add("specialty_name=${Uri.encodeComponent(specialtyName)}");
      
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management groups: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> getManagementDocuments({
    String? query,
    int? facultyId,
    String? title,
    String? educationType,
    String? educationForm,
    String? levelName,
    String? specialtyName,
    String? groupNumber,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String>[];
      if (query != null && query.isNotEmpty) queryParams.add("query=${Uri.encodeComponent(query)}");
      if (facultyId != null) queryParams.add("faculty_id=$facultyId");
      if (title != null && title.isNotEmpty) queryParams.add("title=${Uri.encodeComponent(title)}");
      if (educationType != null) queryParams.add("education_type=${Uri.encodeComponent(educationType)}");
      if (educationForm != null) queryParams.add("education_form=${Uri.encodeComponent(educationForm)}");
      if (levelName != null) queryParams.add("level_name=${Uri.encodeComponent(levelName)}");
      if (specialtyName != null) queryParams.add("specialty_name=${Uri.encodeComponent(specialtyName)}");
      if (groupNumber != null) queryParams.add("group_number=${Uri.encodeComponent(groupNumber)}");
      queryParams.add("page=$page");
      queryParams.add("limit=$limit");

      String url = ApiConstants.managementDocumentsArchive;
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management documents: $e");
    }
    return {"success": false, "data": []};
  }

  Future<Map<String, dynamic>> exportManagementDocumentsZip({
    String? query,
    int? facultyId,
    String? title,
    String? educationType,
    String? educationForm,
    String? levelName,
    String? specialtyName,
    String? groupNumber,
  }) async {
    try {
      final queryParams = <String>[];
      if (query != null && query.isNotEmpty) queryParams.add("query=${Uri.encodeComponent(query)}");
      if (facultyId != null) queryParams.add("faculty_id=$facultyId");
      if (title != null && title.isNotEmpty) queryParams.add("title=${Uri.encodeComponent(title)}");
      if (educationType != null) queryParams.add("education_type=${Uri.encodeComponent(educationType)}");
      if (educationForm != null) queryParams.add("education_form=${Uri.encodeComponent(educationForm)}");
      if (levelName != null) queryParams.add("level_name=${Uri.encodeComponent(levelName)}");
      if (specialtyName != null) queryParams.add("specialty_name=${Uri.encodeComponent(specialtyName)}");
      if (groupNumber != null) queryParams.add("group_number=${Uri.encodeComponent(groupNumber)}");

      String url = "${ApiConstants.backendUrl}/management/documents/export-zip";
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      final response = await _post(url);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error exporting documents zip: $e");
    }
    return {"success": false, "message": "Xatolik yuz berdi"};
  }

  Future<Map<String, dynamic>> getStudentFullDetails(int studentId) async {
    try {
      final response = await _get("${ApiConstants.managementStudents}/$studentId/full-details");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error fetching student full details: $e");
    }
    return {};
  }

  // 3. Get Activities
  Future<List<dynamic>> getActivities() async {
    try {
      debugPrint("DataService: Fetching activities...");
      final response = await _get(ApiConstants.activities);
      
      debugPrint("DataService: Activities response: ${response.statusCode}");
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
    } catch (e) {
      debugPrint("DataService API error: $e");
    }
    return [];
  }

  // NEW: Init Upload Session
  // NEW: Init Upload Session
  Future<Map<String, dynamic>> initUploadSession(String sessionId, String category) async {
    final token = await _authService.getToken();
    final response = await _post('${ApiConstants.activities}/upload/init', body: {
        'session_id': sessionId,
        'category': category
      },);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to init session: ${response.data}');
    }
  }

  // NEW: Check Upload Status
  Future<Map<String, dynamic>> checkUploadStatus(String sessionId) async {
    final token = await _authService.getToken();
    final response = await _get('${ApiConstants.activities}/upload/status/$sessionId');

    if (response.statusCode == 200) {
      return response.data;
    }
    return {"status": "pending"};
  }

  // --- TUTOR BULK ACTIVITY ENDPOINTS ---
  Future<Map<String, dynamic>> tutorInitUploadSession(String sessionId, String category) async {
    final token = await _authService.getToken();
    final response = await _post(ApiConstants.tutorActivitiesUploadInit, body: {
        'session_id': sessionId,
        'category': category
      },);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to init tutor upload: ${response.data}');
    }
  }

  Future<Map<String, dynamic>> tutorCheckUploadStatus(String sessionId) async {
    final response = await _get('${ApiConstants.tutorActivitiesUploadStatus}/$sessionId');

    if (response.statusCode == 200) {
      return response.data;
    }
    return {"status": "pending"};
  }

  Future<Map<String, dynamic>> createTutorBulkActivities({
    required String category,
    required String name,
    required String description,
    required String date,
    required List<int> studentIds,
    String? sessionId,
  }) async {
    final payload = {
      "category": category,
      "name": name,
      "description": description,
      "date": date,
      "student_ids": studentIds,
      if (sessionId != null) "session_id": sessionId,
    };

    final response = await _post(
      ApiConstants.tutorActivitiesBulk,
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to create tutor bulk activities: ${response.data}');
    }
  }
  // --- END TUTOR BULK ACTIVITY ENDPOINTS ---


  // NEW: Unlink Telegram Account
  Future<Map<String, dynamic>> unlinkTelegram() async {
    final response = await authPost('${ApiConstants.backendUrl}/student/unlink-telegram');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to unlink Telegram: ${response.data}');
    }
  }

    Future<dio.Response?> addActivity(String category, String name, String description, String date, {String? sessionId}) async {
    try {
      final formData = dio.FormData.fromMap({
        'category': category,
        'name': name,
        'description': description,
        'date': date,
        if (sessionId != null) 'session_id': sessionId,
      });

      final response = await _post(ApiConstants.activities, body: formData);
      return response;
    } catch (e) {
      debugPrint("Add Activity Exception: $e");
      rethrow;
    }
  }

  // Edit Activity
    Future<dio.Response?> editActivity(String id, String category, String name, String description, String date) async {
    try {
      final formData = dio.FormData.fromMap({
        'category': category,
        'name': name,
        'description': description,
        'date': date,
      });
      return await _patch('${ApiConstants.activities}/$id', body: formData);
    } catch (e) {
      debugPrint("Edit Activity Exception: $e");
      rethrow;
    }
  }
  Future<bool> deleteActivity(String id) async {
    try {
      final response = await _delete('${ApiConstants.activities}/$id');
      
      if (response.statusCode == 200) {
        return true;
      }
      debugPrint("Delete Activity Error: ${response.statusCode}");
      return false;
    } catch (e) {
      debugPrint("Delete Activity Exception: $e");
      return false;
    }
  }

  // 4. Get Clubs

  Future<bool> updateClub(int clubId, Map<String, dynamic> data) async {
    try {
      final response = await _put('${ApiConstants.backendUrl}/student/clubs/$clubId', body: json.encode(data)).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteClub(int clubId) async {
    try {
      final response = await _delete('${ApiConstants.backendUrl}/student/clubs/$clubId').timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getClubs() async {
    try {
      final response = await _get('${ApiConstants.backendUrl}/student/clubs/all').timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching clubs: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> createClub(Map<String, dynamic> data) async {
    try {
      final response = await _post('${ApiConstants.backendUrl}/student/clubs/', body: json.encode(data)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Klub yaratishda xatolik'};
    } catch (e) {
      debugPrint("DataService: Error creating club: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getMyClubs() async {
    try {
      final response = await _get('${ApiConstants.backendUrl}/student/clubs/my').timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> joinClub(int clubId) async {
    try {
      final response = await _post('${ApiConstants.backendUrl}/student/clubs/join', body: json.encode({'club_id': clubId})).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error joining club: $e");
    }
    return {'status': 'error', 'message': 'Tarmoq xatosi'};
  }

  // Club Role-Based Endpoints
  Future<List<dynamic>> getClubMembers(int clubId) async {
    try {
      final response = await _get('${ApiConstants.backendUrl}/student/clubs/$clubId/members').timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<bool> removeClubMember(int clubId, int studentId) async {
    try {
      final response = await _delete('${ApiConstants.backendUrl}/student/clubs/$clubId/members/$studentId').timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    return false;
  }

  Future<List<dynamic>> getClubAnnouncements(int clubId) async {
    try {
      final response = await _get('${ApiConstants.backendUrl}/student/clubs/$clubId/announcements').timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<bool> createClubAnnouncement(int clubId, String content, bool sendToTelegram, {String? mediaUrl}) async {
    try {
      final body = {
        'content': content,
        'send_to_telegram': sendToTelegram,
        if (mediaUrl != null) 'media_url': mediaUrl,
      };
      final response = await _post('${ApiConstants.backendUrl}/student/clubs/$clubId/announcements', body: json.encode(body)).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<dynamic>> getClubEvents(int clubId) async {
    try {
      final response = await _get('${ApiConstants.backendUrl}/student/clubs/$clubId/events').timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<bool> createClubEvent(int clubId, Map<String, dynamic> data) async {
    try {
      final response = await _post('${ApiConstants.backendUrl}/student/clubs/$clubId/events', body: json.encode(data)).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> completeEventActivity(int eventId, int studentId, String status) async {
    try {
      final response = await _post(
        '${ApiConstants.backendUrl}/student/clubs/events/$eventId/complete_activity',
        body: json.encode({"student_id": studentId, "attendance_status": status}),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // Announcements
  Future<List<AnnouncementModel>> getAnnouncementModels() async {
    try {
      final response = await _get(ApiConstants.announcements);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final List<dynamic> list = body['data'];
          return list.map((item) => AnnouncementModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
    }
    return [];
  }

  // Banner
  Future<BannerModel?> getActiveBanner() async {
    try {
      final response = await _get(ApiConstants.banner);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['active'] == true) {
           return BannerModel.fromJson(body);
        }
      }
    } catch (e) {
      debugPrint("Error fetching banner: $e");
    }
    return null;
  }

  // [NEW] Get multiple banners for carousel
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await _get('${ApiConstants.backendUrl}/banner/list');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
           final List<dynamic> list = body['data'];
           return list.map((item) => BannerModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching banners list: $e");
    }
    return [];
  }

  Future<void> trackBannerClick(int bannerId) async {
    try {
      await _post('${ApiConstants.banner}/click/$bannerId');
    } catch (e) {
      debugPrint("Error tracking banner click: $e");
    }
  }

  Future<bool> markAnnouncementModelAsRead(int id) async {
    try {
      final response = await _post('${ApiConstants.announcements}/$id/read');
      if (response.statusCode == 200) {
        final body = response.data;
        return body['success'] == true;
      }
    } catch (e) {
      debugPrint("Error marking announcement as read: $e");
    }
    return false;
  }

  // 5. Get Feedback
  Future<List<dynamic>> getMyFeedback() async {
    try {
      final response = await _get(ApiConstants.feedback).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return response.data;
    } catch (e) {
      debugPrint("Feedback Load Error: $e");
    }
    return [];
  }

  // 6. Send Feedback (Multipart)
    Future<bool> sendFeedback(String text, String role, String? filePath, {bool isAnonymous = false}) async {
    try {
      final formData = dio.FormData.fromMap({
        'text': text,
        'role': role,
        'is_anonymous': isAnonymous.toString(),
        if (filePath != null) 'file': await dio.MultipartFile.fromFile(filePath),
      });

      final response = await _post(ApiConstants.feedback, body: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Feedback Send Error: $e");
      return false;
    }
  }

  // 6.5 Get Feedback Detail (Chat)
  Future<Map<String, dynamic>?> getFeedbackDetail(int id) async {
    try {
      final response = await _get('${ApiConstants.feedback}$id').timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Feedback Detail Error: $e");
    }
    return null;
  }

  // 6.6 Reply to Feedback
  Future<void> replyToFeedback(int id, String text) async {
    final token = await _authService.getToken();
    final response = await _post('${ApiConstants.feedback}$id/reply', body: {'text': text},).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to reply');
    }
  }


  // 7. Get Documents
  Future<List<dynamic>> getMyDocuments() async {
    final response = await _get(ApiConstants.documents).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return response.data;
    throw Exception('Failed to load documents');
  }

  // 9. Get Detailed Attendance List
  Future<List<Attendance>> getAttendanceList({String? semester, bool forceRefresh = false}) async {
    final student = await _authService.getSavedUser();
    final studentId = student?.id ?? 0;
    final semCode = semester ?? 'all';

    // 1. Skip Local Cache - Always Fetch from API (User Request)
    // if (!forceRefresh) { ... }

    return await _backgroundRefreshAttendance(studentId, semCode, refresh: forceRefresh);
  }

  Future<List<Attendance>> _backgroundRefreshAttendance(int studentId, String semCode, {bool refresh = false}) async {
    try {
      String url = ApiConstants.attendanceList;
      List<String> queryParams = [];
      
      if (semCode != 'all') {
        queryParams.add("semester=$semCode");
      }
      if (refresh) {
        queryParams.add("refresh=true");
      }
      
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join('&')}";
      }

      final response = await _get(url);

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map && body.containsKey('data') ? body['data'] : body;
        final List<dynamic> items = (data is List) ? data : (data['items'] ?? []);
        
        // DISABLED LOCAL CACHE: No update
        // await _dbService.saveCache('attendance', studentId, {'items': items}, semesterCode: semCode);
        
        return items.map((json) => Attendance.fromJson(json)).toList();
      }
    } catch (e) {
       print("Attendance Sync Error: $e");
    }
    return [];
  }

  // 11. Get Weekly Schedule
  Future<List<Lesson>> getSchedule({String? targetDate}) async {
    final student = await _authService.getSavedUser();
    final studentId = student?.id ?? 0;
    
    // DISABLED LOCAL CACHE
    // final cached = await _dbService.getCache('schedule', studentId);
    // if (cached != null && cached.containsKey('items')) {
    //    final List<dynamic> items = cached['items'];
    //    // _backgroundRefreshSchedule(studentId);
    //    return items.map((json) => Lesson.fromJson(json)).toList();
    // }

    return await _backgroundRefreshSchedule(studentId, targetDate: targetDate);
  }

  // 12. Get Rent Subsidy Report
  Future<List<dynamic>> getRentSubsidyReport({int? year}) async {
    try {
      String url = '${ApiConstants.backendUrl}/payment/subsidy';
      if (year != null) {
        url += '?year=$year';
      }
      
      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching subsidy report: $e");
    }
    return [];
  }

  Future<List<Lesson>> _backgroundRefreshSchedule(int studentId, {String? targetDate}) async {
    try {
      String url = ApiConstants.scheduleList;
      if (targetDate != null) {
        url += "?target_date=$targetDate";
      }
      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final List<dynamic> items = body['data'];
          // await _dbService.saveCache('schedule', studentId, {'items': items});
          return items.map((json) => Lesson.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Schedule Sync Error: $e");
    }
    return [];
  }

  // Change Password
  Future<bool> changePassword(String newPassword) async {
    try {
      final response = await _post(
        '${ApiConstants.backendUrl}/student/password',
        body: {'password': newPassword},
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          // Update locally stored password too
          await _authService.updateSavedPassword(newPassword);
          return true;
        }
      } else {
        final body = response.data;
        throw Exception(body['detail'] ?? "Xatolik yuz berdi");
      }
    } catch (e) {
      debugPrint("Change Password Error: $e");
      rethrow;
    }
    return false;
  }

  // Update Profile (Phone, Email, Password)
  Future<bool> updateProfile(String phone, String email, String? newPassword) async {
    try {
      final Map<String, dynamic> body = {
        'phone': phone,
        'email': email,
      };
      if (newPassword != null && newPassword.isNotEmpty) {
        body['password'] = newPassword;
      }
      
      final response = await _post(
        '${ApiConstants.backendUrl}/student/profile',
        body: body,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          // If password changed, update locally stored password too
          if (newPassword != null && newPassword.isNotEmpty) {
             await _authService.updateSavedPassword(newPassword);
          }
          return true;
        }
      } else {
        final body = response.data;
        throw Exception(body['detail'] ?? "Xatolik yuz berdi");
      }
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      rethrow;
    }
    return false;
  }


  // 12. Get Detailed Grades (O'zlashtirish)
  Future<List<dynamic>> getGrades({String? semester, bool forceRefresh = false}) async {
    final student = await _authService.getSavedUser();
    final studentId = student?.id ?? 0;
    
    // User requested to remove cache usage for grades.
    // Always force refresh to ensure fresh data from backend.
    return await _backgroundRefreshGrades(studentId, semester: semester, forceRefresh: true);
  }

  Future<List<dynamic>> _backgroundRefreshGrades(int studentId, {String? semester, bool forceRefresh = false}) async {
    try {
      String url = ApiConstants.grades;
      // Build query parameters
      Map<String, String> queryParams = {};
      if (semester != null) queryParams['semester'] = semester;
      if (forceRefresh) queryParams['refresh'] = 'true';
      
      if (queryParams.isNotEmpty) {
        url += (url.contains('?') ? '&' : '?') + Uri(queryParameters: queryParams).query;
      }
      
      final response = await _get(url);

      if (response.statusCode == 200) {
        final dynamic body = response.data;
        List<dynamic> items = [];
        
        if (body is Map && body['success'] == true) {
           items = body['data'] ?? [];
        } else if (body is List) {
           items = body;
        }

        if (items.isNotEmpty) {
          // DISABLED LOCAL CACHE: No update
          // try {
          //   final semCode = semester ?? 'all';
          //   final dynamic cached = await _dbService.getCache('subjects', studentId, semesterCode: semCode);
          //   final Map<String, dynamic> existing = (cached is Map) ? Map<String, dynamic>.from(cached) : {};
          //   existing['grades'] = items;
          //   await _dbService.saveCache('subjects', studentId, existing, semesterCode: semCode);
          // } catch (e) {
          //   print("Warning: Failed to cache grades: $e");
          // }
          return items;
        }
      } else {
        print("Grades API Error: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print("Grades Sync Error: $e");
    }
    return [];
  }
  

  // NEW: Get Semesters
  Future<List<dynamic>> getSemesters({bool refresh = false}) async {
    try {
      String url = "${ApiConstants.academic}/semesters";
      if (refresh) {
        url += "?refresh=true";
      }
      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      print("DataService: Error fetching semesters: $e");
    }
    return [];
  }

  // 13. Get Detailed Subjects
  // 13. Get Detailed Subjects
  Future<List<dynamic>> getSubjects({String? semester, bool refresh = false}) async {
    final student = await _authService.getSavedUser();
    final studentId = student?.id ?? 0;

    // DISABLED LOCAL CACHE: Force live data
    // if (!refresh) {
    //   final cached = await _dbService.getCache('subjects', studentId, semesterCode: semester ?? 'all');
    //   if (cached != null && cached.containsKey('list')) {
    //     // Disable silent background refresh to prevent stale backend data from overwriting fresh local cache ("rollback" bug)
    //     // _backgroundRefreshSubjects(studentId, semester: semester);
    //     return cached['list'];
    //   }
    // }
    return await _backgroundRefreshSubjects(studentId, semester: semester, refresh: refresh);
  }

  Future<List<dynamic>> _backgroundRefreshSubjects(int studentId, {String? semester, bool refresh = false}) async {
    try {
      String url = ApiConstants.subjects;
      
      // Add Query Params
      final params = <String>[];
      if (semester != null) params.add("semester=$semester");
      if (refresh) params.add("refresh=true");
      
      if (params.isNotEmpty) {
        url += "?${params.join("&")}";
      }

      final response = await _get(url);

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final items = body['data'];
          // DISABLED LOCAL CACHE: No update
          // await _dbService.saveCache('subjects', studentId, {'list': items}, semesterCode: semester ?? 'all');
          return items;
        }
      }
    } catch (e) {
      print("Subjects Sync Error: $e");
    }
    return [];
  }

  // 14. Get Subject Resources
  Future<List<dynamic>> getResources(String subjectId) async {
    try {
      final response = await _get("${ApiConstants.resources}/$subjectId").timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
      return [];
    } catch (e) {
      print("DataService: Error fetching resources: $e");
      return [];
    }
  }

  // 15. Send Resource to Bot
  Future<bool> sendResourceToBot(String url, String name) async {
    try {
      final response = await _post("${ApiConstants.resources}/send", body: json.encode({"url": url, "name": name})
      );

      if (response.statusCode == 200) {
        final body = response.data;
        print("Bot Send dio.Response: $body");
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      print("DataService: Error sending resource: $e");
      return false;
    }
  }

  // 16. Get Subject Details
  Future<Map<String, dynamic>?> getSubjectDetails(String subjectId, {String? semesterId}) async {
    try {
      String url = "${ApiConstants.academic}/subject/$subjectId/details";
      if (semesterId != null && semesterId.isNotEmpty) {
        url += "?semester=$semesterId";
      }
      
      final response = await _get(url);

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
      return null;
    } catch (e) {
      print("DataService: Error fetching subject details: $e");
      return null;
    }
  }

  // 17. Send AI Message
  // 17. Send AI Message (Old version - for backward compatibility)
  Future<String?> sendAiMessage(String message) async {
    try {
      final response = await _post(ApiConstants.aiChat, body: json.encode({'message': message}));

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
           return body['data'];
        }
      } else if (response.statusCode == 403) {
        throw Exception("PREMIUM_REQUIRED");
      }
      return null;
    } catch (e) {
      if (e.toString().contains("PREMIUM_REQUIRED")) rethrow;
      print("DataService: Error sending AI message: $e");
      return null;
    }
  }

  // 17.2 Send AI Chat (New version - with keywords)
  Future<Map<String, dynamic>> sendAiChat({String? keyword, String? text, String? question}) async {
    try {
      final response = await _post(ApiConstants.aiChat, body: json.encode({
          if (keyword != null) 'keyword': keyword,
          if (text != null) 'text': text,
          if (question != null) 'question': question,
        }));

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 403) {
        throw Exception("PREMIUM_REQUIRED");
      } else {
        return response.data;
      }
    } catch (e) {
      if (e.toString().contains("PREMIUM_REQUIRED")) rethrow;
      debugPrint("DataService: Error in AI chat: $e");
      return {"success": false, "error": e.toString()};
    }
  }


  // 17.5 Predict Grant
  Future<String?> predictGrant() async {
    try {
      final response = await _post('${ApiConstants.backendUrl}/ai/predict-grant');

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
      return null;
    } catch (e) {
      if (e.toString().contains("PREMIUM_REQUIRED")) rethrow;
      print("DataService: Error predicting grant: $e");
      return null;
    }
  }

  // 18. Get AI History
  Future<List<dynamic>?> getAiHistory() async {
    try {
      final response = await _get('${ApiConstants.backendUrl}/ai/history');

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
           return body['data'];
        }
      }
      return null;
    } catch (e) {
      print("DataService: Error fetching AI history: $e");
      return null;
    }
  }

  // 19. Clear AI History
  Future<bool> clearAiHistory() async {
    try {
      final response = await _delete('${ApiConstants.backendUrl}/ai/history');

      return response.statusCode == 200;
    } catch (e) {
      print("DataService: Error clearing AI history: $e");
      return false;
    }
  }
  // 20. Document Management
  Future<List<dynamic>> getDocuments() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/student/documents");
      if (response.statusCode == 200) {
        final data = response.data;
        return data['data'] ?? [];
      }
    } catch (e) {
      print("DataService: Error getting documents: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> initiateDocUpload({required String sessionId, String? category, String? title}) async {
    try {
      final response = await _post(
        "${ApiConstants.backendUrl}/student/documents/init-upload",
        body: {
          'session_id': sessionId,
          'category': category,
          'title': title,
        },
      );
      return response.data;
    } catch (e) {
      print("DataService: Error initiating upload: $e");
      return {"success": false, "message": "Tarmoq xatosi"};
    }
  }

  Future<Map<String, dynamic>> checkDocUploadStatus(String sessionId) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/student/documents/upload-status/$sessionId");
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("DataService: Error checking status: $e");
    }
    return {"status": "pending"};
  }

  Future<Map<String, dynamic>> finalizeDocUpload(String sessionId) async {
    try {
      final response = await _post(
        "${ApiConstants.backendUrl}/student/documents/finalize",
        body: {'session_id': sessionId},
      );
      return response.data;
    } catch (e) {
      print("DataService: Error finalizing upload: $e");
      return {"success": false, "message": "Tarmoq xatosi"};
    }
  }

  Future<Map<String, dynamic>> initiateFeedbackUpload({
    required String sessionId,
    required String text,
    String role = "dekanat",
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _post(
        "${ApiConstants.backendUrl}/student/feedback/init-upload",
        body: {
          'session_id': sessionId,
          'text': text,
          'role': role,
          'is_anonymous': isAnonymous,
        },
      );
      return response.data;
    } catch (e) {
      print("DataService: Error initiating feedback upload: $e");
      return {"success": false, "message": "Tarmoq xatosi"};
    }
  }

  // 24. Election Methods
  Future<Map<String, dynamic>> getElectionDetails(int electionId) async {
    final response = await _get("${ApiConstants.backendUrl}/election/$electionId");
    if (response.statusCode == 200) {
      final body = response.data;
      // Support both wrapped {"success": true, "data": {...}} and raw {...}
      if (body is Map<String, dynamic>) {
        return body['data'] ?? body;
      }
    }
    return {};
  }
  
  // ==========================================================
  // TYUTOR MODULE
  // ==========================================================
  
  // 30. Get Tutor Groups
  Future<List<dynamic>> getTutorGroups() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/groups");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching tutor groups: $e");
    }
    return [];
  }
  

  // 30.1 Get Group Appeals
  Future<List<dynamic>> getGroupAppeals(String groupNumber) async {
    debugPrint("DataService: Fetching appeals for group '$groupNumber'...");
    try {
      final url = "${ApiConstants.backendUrl}/tutor/groups/${groupNumber.trim()}/appeals";
      debugPrint("DataService: URL: $url");
      final response = await _get(url);
      
      debugPrint("DataService: Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final list = body['data'] as List;
          debugPrint("DataService: Found ${list.length} appeals");
          return list;
        } else {
             debugPrint("DataService: Success false. Message: ${body['message']}");
        }
      } else {
         debugPrint("DataService: Error Error Body: ${response.data}");
      }
    } catch (e) {
      debugPrint("DataService: Error fetching group appeals: $e");
    }
    return [];
  }

  // 30.2 Reply to Appeal (Tutor)
  Future<void> replyToTutorAppeal(int appealId, String text) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('${ApiConstants.backendUrl}/tutor/appeals/$appealId/reply?text=${Uri.encodeComponent(text)}');
    
    final response = await _post(uri.toString());

    if (response.statusCode != 200) {
      throw Exception("Failed to reply: ${response.data}");
    }
  }

  // 30.3 Get All Tutor Appeals
  Future<List<dynamic>> getTutorAllAppeals({String? status}) async {
    try {
      String url = "${ApiConstants.backendUrl}/tutor/appeals";
      if (status != null && status.isNotEmpty) {
        url += "?status=$status";
      }
      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'] as List;
      }
    } catch (e) {
      debugPrint("Error fetching tutor appeals: $e");
    }
    return [];
  }

  // 30.4 Get Tutor Appeals Stats
  Future<Map<String, dynamic>> getTutorAppealsStats() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/appeals/stats");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['stats'];
      }
    } catch (e) {
      debugPrint("Error fetching tutor appeals stats: $e");
    }
    return {"pending": 0, "answered": 0, "resolved": 0};
  }

  // 30.5 Get Tutor Appeal Detail
  Future<Map<String, dynamic>?> getTutorAppealDetail(int id) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/appeals/$id");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['detail'];
      }
    } catch (e) {
      debugPrint("Error fetching tutor appeal detail: $e");
    }
    return null;
  }

  // 31. Get Tutor Dashboard
  Future<Map<String, dynamic>> getTutorDashboard() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/dashboard");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) return body['data'];
      }
    } catch (e) {
      debugPrint("DataService: Error fetching tutor dashboard: $e");
    }
    return {};
  }

  Future<Map<String, dynamic>> getTutorRatingStats() async {
    try {
      final response = await _get(ApiConstants.tutorRatingStats);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching tutor rating stats: $e");
    }
    return {};
  }
  
  // 32. Get Tutor Students
  Future<List<dynamic>> getTutorStudents({String? group}) async {
    try {
      String url = "${ApiConstants.backendUrl}/tutor/students";
      if (group != null) {
        url += "?group=$group";
      }
      
      final response = await _get(url);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching tutor students: $e");
    }
    return [];
  }

  Future<bool> voteInElection(int electionId, int candidateId) async {
    final response = await _post(
      "${ApiConstants.backendUrl}/election/$electionId/vote",
      body: {"candidate_id": candidateId},
    );
    if (response.statusCode == 200) return true;
    final body = response.data;
    throw Exception(body['detail'] ?? "Ovoz berishda xato yuz berdi");
  }

  // 34. Get Tutor Activity Stats
  Future<List<dynamic>?> getTutorActivityStats() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/activities/stats");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching activity stats: $e");
      return null;
    }
    return [];
  }

  // 34.5 Get Tutor Recent Activities (and general stat)
  Future<Map<String, dynamic>?> getTutorRecentActivities() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/activities/recent");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body;
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching recent activities: $e");
      return null;
    }
    return null;
  }

  // 35. Get Group Activities
  Future<List<dynamic>?> getGroupActivities(String groupNumber) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/activities/group/$groupNumber");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching group activities: $e");
      return null;
    }
    return [];
  }

  // 36. Review Activity
  Future<bool> reviewActivity(int activityId, String status) async {
    try {
      final response = await _post(
        "${ApiConstants.backendUrl}/tutor/activity/$activityId/review",
        body: {"status": status},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint("DataService: Error reviewing activity: $e");
    }
    return false;
  }
  
  // 37. Legacy Upload Status (if needed) or keep existing
  Future<Map<String, dynamic>> checkFeedbackUploadStatus(String sessionId) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/student/feedback/upload-status/$sessionId");
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("DataService: Error checking feedback status: $e");
    }
    return {"status": "pending"};
  }

    Future<Map<String, dynamic>> createFeedback({
    required String text,
    String role = "dekanat",
    bool isAnonymous = false,
    String? sessionId,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'text': text,
        'role': role,
        'is_anonymous': isAnonymous.toString(),
        if (sessionId != null) 'session_id': sessionId,
      });

      final response = await _post("${ApiConstants.backendUrl}/student/feedback", body: formData);

      if (response.statusCode == 200) {
        return response.data;
      }
      return {"success": false, "message": "Xatolik: ${response.statusCode}"};
    } catch (e) {
      debugPrint("createFeedback error: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  Future<bool> deleteDocument(int docId) async {
    try {
      final response = await _delete("${ApiConstants.backendUrl}/student/documents/$docId");
      return response.statusCode == 200;
    } catch (e) {
      print("DataService: Error deleting document: $e");
      return false;
    }
  }

  Future<String?> sendDocumentToBot(int docId, String type) async {
    try {
      final response = await _post("${ApiConstants.backendUrl}/student/documents/$docId/send-to-bot", body: json.encode({'type': type}));

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
           return body['message'];
        } else {
           return body['message']; // Return error message from server
        }
      }
      return null;
    } catch (e) {
      print("DataService: Error requesting document: $e");
      return null;
    }
  }
  // 21. Certificate Management
  Future<List<dynamic>> getCertificates() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/student/certificates");
      if (response.statusCode == 200) {
        final data = response.data;
        return data['data'] ?? [];
      }
    } catch (e) {
      print("DataService: Error getting certificates: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> initiateCertificateUpload({required String sessionId, String? title}) async {
    try {
      final response = await _post(
        "${ApiConstants.backendUrl}/student/certificates/init-upload",
        body: {
          'session_id': sessionId,
          'title': title,
        },
      );
      return response.data;
    } catch (e) {
      print("DataService: Error initiating certificate upload: $e");
      return {"success": false, "message": "Tarmoq xatosi"};
    }
  }

  Future<Map<String, dynamic>> checkCertUploadStatus(String sessionId) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/student/certificates/upload-status/$sessionId");
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("DataService: Error checking certificate status: $e");
    }
    return {"status": "pending"};
  }

  Future<Map<String, dynamic>> finalizeCertUpload(String sessionId) async {
    try {
      final response = await _post(
        "${ApiConstants.backendUrl}/student/certificates/finalize",
        body: {'session_id': sessionId},
      );
      return response.data;
    } catch (e) {
      print("DataService: Error finalizing certificate upload: $e");
      return {"success": false, "message": "Tarmoq xatosi"};
    }
  }

  Future<bool> deleteCertificate(int certId) async {
    try {
      final response = await _delete("${ApiConstants.backendUrl}/student/certificates/$certId");
      return response.statusCode == 200;
    } catch (e) {
      print("DataService: Error deleting certificate: $e");
      return false;
    }
  }

  Future<String?> sendCertificateToBot(int certId, String emoji) async {
    try {
      final response = await _post("${ApiConstants.backendUrl}/student/certificates/$certId/send-to-bot", body: json.encode({"emoji": emoji}));
      
      if (response.statusCode == 200) {
        final body = response.data;
        return body['message'] ?? "Yuborildi";
      }
      return null;
    } catch (e) {
      print("DataService: Error updating badge: $e");
      return null;
    }
  }

  // --- Surveys (So'rovnomalar) ---

  Future<SurveyListResponse> getSurveys() async {
    final response = await _get(ApiConstants.surveys);
    if (response.statusCode == 200) {
      return SurveyListResponse.fromJson(response.data);
    }
    throw Exception('Failed to load surveys');
  }

  Future<SurveyStartResponse> startSurvey(int surveyId) async {
    final response = await _post(
      ApiConstants.surveyStart,
      body: {'survey_id': surveyId},
    );
    if (response.statusCode == 200) {
      return SurveyStartResponse.fromJson(response.data);
    }
    throw Exception('Failed to start survey');
  }

  Future<bool> submitSurveyAnswer(int questionId, String buttonType, dynamic answer) async {
    final response = await _post(
      ApiConstants.surveyAnswer,
      body: {
        'question_id': questionId,
        'button_type': buttonType,
        'answer': answer,
      },
    );
    if (response.statusCode == 200) {
      final body = response.data;
      return body['success'] == true;
    }
    return false;
  }

  Future<bool> finishSurvey(int quizRuleId) async {
    final response = await _post(
      ApiConstants.surveyFinish,
      body: {'quiz_rule_id': quizRuleId},
    );
    if (response.statusCode == 200) {
      final body = response.data;
      return body['success'] == true;
    }
    return false;
  }

  // 36. Get Tutor Document Stats
  Future<List<dynamic>?> getTutorDocumentStats() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/documents/stats");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching document stats: $e");
      return null;
    }
    return [];
  }

  // 37. Get Group Document Details
  Future<List<dynamic>?> getGroupDocumentDetails(String groupNumber) async {
    try {
      String encodedGroup = Uri.encodeComponent(groupNumber);
      final response = await _get("${ApiConstants.backendUrl}/tutor/documents/group/$encodedGroup");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching group document details: $e");
      return null;
    }
    return [];
  }

  // 38. Get All Document Details
  Future<List<dynamic>?> getAllDocumentDetails() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/documents/all");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching all document details: $e");
      return null;
    }
    return [];
  }

  // 39. Send Document Request Notification
  Future<bool> sendDocumentRequest(int studentId, String? category) async {
    try {
      final token = await _authService.getToken();
      String url = "${ApiConstants.backendUrl}/tutor/documents/request";
      
      final response = await _post(url, body: json.encode({"student_id": studentId, "category": category ?? "all"})).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint("DataService: Error sending document request: $e");
    }
    return false;
  }

  // 37.1 Get Group Students
  Future<List<dynamic>?> getTutorGroupStudents(String groupNumber) async {
    try {
      String encodedGroup = Uri.encodeComponent(groupNumber);
      final response = await _get("${ApiConstants.tutorGroupStudents}/$encodedGroup");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching group students: $e");
      return null;
    }
    return [];
  }

  // 38. Request Documents
  Future<bool> requestDocuments({int? studentId, String? groupNumber, String? categoryName}) async {
    try {
      final response = await _post(
        "${ApiConstants.backendUrl}/tutor/documents/request",
        body: {
          if (studentId != null) 'student_id': studentId,
          if (groupNumber != null) 'group_number': groupNumber,
          if (categoryName != null) 'category': categoryName,
        },
      );
      if (response.statusCode == 200) {
        final body = response.data;
        return body['success'] == true;
      }
    } catch (e) {
      debugPrint("DataService: Error requesting documents: $e");
    }
    return false;
  }

  // 39. Get Tutor Certificate Stats
  Future<List<dynamic>?> getTutorCertificateStats() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/certificates/stats");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching tutor certificate stats: $e");
      return null;
    }
    return [];
  }

  // 40. Get Group Certificate Details
  Future<List<dynamic>?> getTutorGroupCertificateDetails(dynamic groupNumber) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/certificates/group/${groupNumber.toString()}");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching group certificate details: $e");
      return null;
    }
    return [];
  }

  // 41. Get Student Certificates for Tutor
  Future<List<dynamic>?> getStudentCertificatesForTutor(int studentId) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/tutor/certificates/student/$studentId");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching student certificates for tutor: $e");
      return null;
    }
    return [];
  }

  // 42. Download Student Certificate for Tutor (via Bot)
  Future<String?> downloadStudentCertificateForTutor(int certId) async {
    try {
      final response = await _post("${ApiConstants.backendUrl}/tutor/certificates/$certId/download");
      final body = response.data;
      if (response.statusCode == 200) {
        return body['message'] ?? "Sertifikat botga yuborildi";
      }
      return body['message'] ?? "Xatolik yuz berdi";
    } catch (e) {
      debugPrint("DataService: Error downloading certificate: $e");
      return "Tarmoq xatosi";
    }
  }
  // 43. Management Analytics
  Future<Map<String, dynamic>?> getManagementAnalytics() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/management/analytics");
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management analytics: $e");
    }
    return null;
  }

  // 44. Management AI Report
  Future<String?> getManagementAiReport() async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/management/ai-report", timeout: const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'];
        }
      }
      return "Hisobotni yuklashda xatolik";
    } catch (e) {
      debugPrint("DataService: Error fetching management AI report: $e");
      return "Tarmoq xatosi: $e";
    }
  }

  // 45. Download Student Certificate for Management
  Future<String?> downloadStudentCertificateForManagement(int certId) async {
    try {
      final response = await _post("${ApiConstants.backendUrl}/management/certificates/$certId/download");
      final body = response.data;
      if (response.statusCode == 200) {
        return body['message'] ?? "Sertifikat botga yuborildi";
      }
      return body['message'] ?? "Xatolik yuz berdi";
    } catch (e) {
      debugPrint("DataService: Error downloading certificate for management: $e");
      return "Tarmoq xatosi";
    }
  }

  // 46. Download Student Document for Management
  Future<String?> downloadStudentDocumentForManagement(int docId, {String type = "document"}) async {
    try {
      final response = await _post("${ApiConstants.backendUrl}/management/documents/$docId/download?type=$type");
      final body = response.data;
      if (response.statusCode == 200) {
        return body['message'] ?? "Hujjat botga yuborildi";
      }
      return body['message'] ?? "Xatolik yuz berdi";
    } catch (e) {
      debugPrint("DataService: Error downloading document for management: $e");
      return "Tarmoq xatosi";
    }
  }

  // 47. Predict Sentiment Analysis
  Future<String?> predictSentiment() async {
    try {
      final response = await _post("${ApiConstants.backendUrl}/ai/predict-sentiment");
      final body = response.data;
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'];
      }
      return body['message'] ?? "Tahlil jarayonida xatolik.";
    } catch (e) {
      debugPrint("DataService: Error predicting sentiment: $e");
      return "Tarmoq xatosi yoki server ishlamayapti.";
    }
  }

  // ===================================
  // ANALYTICS & MONITORING
  // ===================================

  Future<Map<String, dynamic>> getAnalyticsDashboard() async {
    final response = await _get(ApiConstants.managementAnalyticsDashboard);
    if (response.statusCode == 200) {
      final body = response.data;
      return body['success'] == true ? body['data'] : body;
    }
    throw Exception('Failed to load dashboard stats');
  }

  Future<Map<String, dynamic>> getManagementActivities({
    String? status,
    String? category,
    int? facultyId,
    String? query,
    String? educationType,
    String? educationForm,
    String? levelName,
    String? specialtyName,
    String? groupNumber,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String>[];
      if (status != null) queryParams.add("status=$status");
      if (category != null) queryParams.add("category=${Uri.encodeComponent(category)}");
      if (facultyId != null) queryParams.add("faculty_id=$facultyId");
      if (query != null && query.isNotEmpty) queryParams.add("query=${Uri.encodeComponent(query)}");
      if (educationType != null) queryParams.add("education_type=${Uri.encodeComponent(educationType)}");
      if (educationForm != null) queryParams.add("education_form=${Uri.encodeComponent(educationForm)}");
      if (levelName != null) queryParams.add("level_name=${Uri.encodeComponent(levelName)}");
      if (specialtyName != null) queryParams.add("specialty_name=${Uri.encodeComponent(specialtyName)}");
      if (groupNumber != null) queryParams.add("group_number=${Uri.encodeComponent(groupNumber)}");
      queryParams.add("page=$page");
      queryParams.add("limit=$limit");

      String url = ApiConstants.managementActivities;
      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      final response = await _get(url);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching management activities: $e");
    }
    return {"success": false, "data": [], "total": 0};
  }

  Future<bool> approveActivity(int activityId) async {
    try {
      final response = await _post("${ApiConstants.managementActivities}/$activityId/approve");
      if (response.statusCode == 200) {
        final body = response.data;
        debugPrint("DataService: Approve dio.Response: $body");
        return body['success'] == true;
      }
    } catch (e, stacktrace) {
      debugPrint("DataService: Error approving activity: $e ($stacktrace)");
    }
    debugPrint("DataService: Approve returning false");
    return false;
  }

  Future<bool> rejectActivity(int activityId, String? comment) async {
    try {
      final response = await _post(
        "${ApiConstants.managementActivities}/$activityId/reject",
        body: {'comment': comment},
      );
      if (response.statusCode == 200) {
        final body = response.data;
        return body['success'] == true;
      }
    } catch (e) {
      debugPrint("DataService: Error rejecting activity: $e");
    }
    return false;
  }

  Future<List<dynamic>> getActivityTrend() async {
    final response = await _get('${ApiConstants.backendUrl}/management/analytics/trend?days=30');
    if (response.statusCode == 200) {
      return List<dynamic>.from(response.data);
    }
    return [];
  }

  Future<List<dynamic>> getFacultyActivityStats() async {
    final response = await _get('${ApiConstants.backendUrl}/management/analytics/faculties');
    if (response.statusCode == 200) {
      return List<dynamic>.from(response.data);
    }
    return [];
  }

  Future<List<dynamic>> getRecentActivitySubmissions() async {
    final response = await _get('${ApiConstants.backendUrl}/management/analytics/recent-submissions?limit=10');
    if (response.statusCode == 200) {
      return List<dynamic>.from(response.data);
    }
    return [];
  }

  // 40. Get Contract Information
  Future<Map<String, dynamic>> getContractInfo({bool forceRefresh = false}) async {
    try {
      final response = await _get("${ApiConstants.backendUrl}/student/contract-info?force_refresh=$forceRefresh");
      if (response.statusCode == 200) {
        final body = response.data;
        
        // Handle both List and Map structures dynamically
        if (body is List) {
           if (body.isNotEmpty && body[0] is Map) {
               return Map<String, dynamic>.from(body[0]);
           }
        } else if (body is Map) {
           // If Backend already returns a Map with attributes/items directly
           if (body.containsKey('attributes') || body.containsKey('items')) {
               return Map<String, dynamic>.from(body);
           }
           // If Backend wraps it in 'data'
           if (body.containsKey('data') && body['data'] is Map) {
               final data = body['data'] as Map;
               if (data.containsKey('attributes') || data.containsKey('items')) {
                   return Map<String, dynamic>.from(data);
               }
           }
        }
        return {};
      }
    } catch (e) {
      debugPrint("DataService: Error fetching contract info: $e");
    }
    return {};
  }

  // --- ACCOMMODATION ---
  Future<List<AccommodationListing>> getAccommodationListings() async {
    try {
      final response = await _get('${ApiConstants.accommodation}/listings');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AccommodationListing.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("DataService: Error fetching accommodation listings: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> createAccommodationListing(Map<String, dynamic> data) async {
    try {
      final response = await _post(
        '${ApiConstants.accommodation}/listings',
        body: data,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error creating accommodation listing: $e");
    }
    return {'success': false, 'message': 'Xatolik yuz berdi'};
  }

  // --- DORMITORY ---
  Future<List<dynamic>> getDormRoommates() async {
    try {
       final response = await _get(ApiConstants.dormRoommates);
       if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getDormRules() async {
    try {
      final response = await _get(ApiConstants.dormRules);
      if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getDormMenu() async {
    try {
      final response = await _get(ApiConstants.dormMenu);
      if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getDormRoster() async {
    try {
      final response = await _get(ApiConstants.dormRoster);
      if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getMyDormIssues() async {
    try {
      final response = await _get(ApiConstants.dormMyIssues);
      if (response.statusCode == 200) return response.data;
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createDormIssue(String category, String description) async {
    try {
      final response = await _post(ApiConstants.dormIssues, body: {
        'category': category,
        'description': description,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getRatingTargets(String roleType) async {
    try {
      final response = await _get('${ApiConstants.ratingTargets}/$roleType');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("DataService: Error fetching rating targets: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> submitRating({
    required int ratedPersonId,
    required String roleType,
    required int rating,
    int? activationId,
    List<Map<String, dynamic>>? answers,
  }) async {
    try {
      final response = await _post(
        ApiConstants.ratingSubmit,
        body: {
          'rated_person_id': ratedPersonId,
          'role_type': roleType,
          'rating': rating,
          if (activationId != null) 'activation_id': activationId,
          if (answers != null) 'answers': answers,
        },
      );
      if (response.statusCode == 200) {
        final body = response.data;
        return {'success': true, 'message': body['message'] ?? 'Bahoyingiz qabul qilindi'};
      } else {
        final body = response.data;
        return {'success': false, 'message': body['detail'] ?? 'Xatolik yuz berdi'};
      }
    } catch (e) {
      debugPrint("DataService: Error submitting rating: $e");
      return {'success': false, 'message': 'Ulanishda xatolik yuz berdi'};
    }
  }

  // Missing methods for Auth Strategy
  Future<void> saveToken(String token) async {
    await _authService.saveToken(token);
  }

  Future<void> logout() async {
    await _authService.clearToken();
    await _dbService.clearAll();
  }

  void updateUniversityServer(String prefix) {
    _apiClient.updateBaseUrl(prefix);
  }
  // [NEW] Exposed for Offline Support
  Future<Student?> getSavedUser() => _authService.getSavedUser();

}