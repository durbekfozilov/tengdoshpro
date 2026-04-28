import 'package:flutter/material.dart';
import '../../../../core/network/data_service.dart';

class ProDashboardProvider with ChangeNotifier {
  final DataService _dataService;
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  ProDashboardProvider(this._dataService) {
    fetchStats();
  }

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  // Convenience getters for typical management stats
  int get studentCount => _stats['students_count'] ?? 0;
  int get pendingAppeals => _stats['pending_appeals_count'] ?? 0;
  int get activeLessons => _stats['active_lessons_count'] ?? 0;
  int get pendingActivities => _stats['pending_activities_count'] ?? 0;

  Future<void> fetchStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetching from the newly refactored DataService
      _stats = await _dataService.getManagementDashboard(refresh: true);
    } catch (e) {
      debugPrint("ProDashboardProvider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
