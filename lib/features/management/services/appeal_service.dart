import 'package:dio/dio.dart' as dio;
import 'package:talabahamkor_mobile/core/constants/api_constants.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';
import 'package:talabahamkor_mobile/core/network/api_client.dart';
import '../models/appeal_model.dart';
import '../../appeals/models/appeal_model.dart' as student_models;

class AppealService {
  final DataService _dataService;

  // Constructor handles optional injection or default initialization
  AppealService([DataService? dataService])
      : _dataService = dataService ?? DataService(ApiClient(dio.Dio()));

  Future<AppealStats> getStats() async {
    try {
      final response = await _dataService.authGet(ApiConstants.managementAppealsStats);
      
      if (response.statusCode == 200) {
        // Use response.data directly as Dio handles JSON decoding
        return AppealStats.fromJson(response.data);
      } else {
        throw Exception('Statistikani yuklab bo\'lmadi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Statistika yuklashda xatolik: $e');
    }
  }

  Future<List<Appeal>> getAppeals({
    int page = 1,
    String? status,
    String? faculty,
    int? facultyId,
    String? aiTopic,
    String? assignedRole
  }) async {
    try {
      String url = '${ApiConstants.managementAppealsList}?page=$page&limit=20';
      if (status != null) url += '&status=$status';
      if (faculty != null) url += '&faculty=$faculty';
      if (facultyId != null) url += '&faculty_id=$facultyId';
      if (aiTopic != null) url += '&ai_topic=$aiTopic';
      if (assignedRole != null) url += '&assigned_role=$assignedRole';

      final response = await _dataService.authGet(url);

      if (response.statusCode == 200) {
        // Dio already decodes JSON, handle both List and Map responses
        final rawData = response.data;
        final List data = rawData is List ? rawData : (rawData['data'] ?? []);
        return data.map((e) => Appeal.fromJson(e)).toList();
      } else {
        throw Exception('Murojaatlarni yuklab bo\'lmadi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Murojaatlarni yuklashda xatolik: $e');
    }
  }

  Future<void> resolveAppeal(int id) async {
    try {
      final url = '${ApiConstants.managementAppealsResolve}/$id/resolve';
      final response = await _dataService.authPost(url);

      if (response.statusCode != 200) {
        throw Exception('Murojaatni yopib bo\'lmadi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Murojaatni yopishda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> clusterAppeals() async {
    try {
      final response = await _dataService.authPost(ApiConstants.aiClusterAppeals);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('AI Tahlil xatosi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI Tahlil jarayonida xatolik: $e');
    }
  }

  Future<void> forwardAppeal(int id, String targetRole) async {
    try {
      final url = '${ApiConstants.managementAppealsResolve}/$id/forward';
      final response = await _dataService.authPost(
        url,
        body: {'role': targetRole},
      );

      if (response.statusCode != 200) {
        throw Exception('Murojaatni yo\'naltirib bo\'lmadi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Yo\'naltirishda xatolik: $e');
    }
  }

  Future<void> replyAppeal(int id, String text) async {
    try {
      final url = '${ApiConstants.managementAppealsResolve}/$id/reply';
      final response = await _dataService.authPost(
        url,
        body: {'text': text},
      );

      if (response.statusCode != 200) {
        throw Exception('Javob yuborishda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Javob yuborishda xatolik: $e');
    }
  }

  Future<student_models.AppealDetail> getAppealDetail(int id) async {
    try {
      final url = '${ApiConstants.managementAppealsResolve}/$id';
      final response = await _dataService.authGet(url);

      if (response.statusCode == 200) {
        return student_models.AppealDetail.fromJson(response.data);
      } else {
        throw Exception('Murojaat tafsilotlarini yuklab bo\'lmadi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Tafsilotlarni yuklashda xatolik: $e');
    }
  }
}
