import 'package:flutter/material.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';

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
      
      if (_pendingActivities.isEmpty) {
        _setMockActivities();
      }
    } catch (e) {
      debugPrint("ScoringProvider: Fetch error: $e");
      _setMockActivities();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setMockActivities() {
    _pendingActivities = [
      {
        'id': 101,
        'student': {'full_name': 'Aliyev Behruz', 'group': '611-21', 'university': 'Tengdosh University'},
        'title': 'Volontyorlik faoliyati - "Mehribonlik uyi" tashrifi',
        'category': 'Ijtimoiy faollik',
        'created_at': '2026-04-28T10:00:00Z',
        'description': 'Toshkent shahridagi 1-sonli Mehribonlik uyiga tashrif buyurib, bolajonlar uchun o\'quv qurollari va sovg\'alar tarqatdik.',
        'files': [
          {'url': 'https://picsum.photos/800/600?sig=1', 'name': 'rasm1.jpg'},
          {'url': 'https://picsum.photos/800/600?sig=2', 'name': 'rasm2.jpg'},
        ]
      },
      {
        'id': 102,
        'student': {'full_name': 'Karimova Malika', 'group': '702-22', 'university': 'Tengdosh University'},
        'title': 'Sport musobaqasi - Universiada 2026 g\'olibi',
        'category': 'Sport va madaniyat',
        'created_at': '2026-04-29T09:30:00Z',
        'description': 'Shaxmat bo\'yicha o\'tkazilgan universitetlararo musobaqada 1-o\'rinni egalladim.',
        'files': [
          {'url': 'https://picsum.photos/800/600?sig=3', 'name': 'diplom.jpg'},
        ]
      }
    ];
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
