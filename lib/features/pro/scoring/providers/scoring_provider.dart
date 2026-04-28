import 'package:flutter/material.dart';
import '../../../../core/network/data_service.dart';

/// Policy-based scoring criteria according to "Nizom"
class ScoringCriteria {
  final String category;
  final int maxPoints;
  int currentPoints;

  ScoringCriteria({required this.category, required this.maxPoints, this.currentPoints = 0});
}

class ScoringProvider with ChangeNotifier {
  final DataService _dataService;
  List<dynamic> _pendingActivities = [];
  bool _isLoading = false;

  ScoringProvider(this._dataService);

  List<dynamic> get pendingActivities => _pendingActivities;
  bool get isLoading => _isLoading;

  // Nizom Logic: Default scoring criteria for social activities
  List<ScoringCriteria> getNewScoringTemplate() => [
    ScoringCriteria(category: "Ijtimoiy faollik", maxPoints: 30),
    ScoringCriteria(category: "Ilmiy salohiyat", maxPoints: 20),
    ScoringCriteria(category: "Sport va madaniyat", maxPoints: 20),
    ScoringCriteria(category: "Tashabbuskorlik", maxPoints: 30),
  ];

  Future<void> fetchPendingActivities() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Requests are now automatically routed to the correct university server
      final response = await _dataService.authGet('/management/activities/pending');
      if (response.statusCode == 200) {
        _pendingActivities = response.data is List ? response.data : (response.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint("ScoringProvider: Fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Implements multi-criteria scoring before approval
  Future<bool> approveWithScore(int id, List<ScoringCriteria> scores, String comment) async {
    final totalScore = scores.fold(0, (sum, item) => sum + item.currentPoints);
    
    try {
      final response = await _dataService.authPost(
        '/management/activities/$id/approve',
        body: {
          'status': 'approved',
          'total_score': totalScore,
          'details': scores.map((s) => {'category': s.category, 'points': s.currentPoints}).toList(),
          'comment': comment,
        },
      );
      
      if (response.statusCode == 200) {
        _pendingActivities.removeWhere((item) => item['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("ScoringProvider: Approval failed: $e");
    }
    return false;
  }

  Future<bool> rejectActivity(int id, String reason) async {
    try {
      final response = await _dataService.authPost(
        '/management/activities/$id/reject',
        body: {'status': 'rejected', 'reason': reason},
      );
      if (response.statusCode == 200) {
        _pendingActivities.removeWhere((item) => item['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("ScoringProvider: Rejection failed: $e");
    }
    return false;
  }
}
