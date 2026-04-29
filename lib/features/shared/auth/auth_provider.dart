import 'package:flutter/material.dart';
import '../../../core/auth/base_auth_repo.dart';
import '../../../core/models/student.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';

class AuthProvider with ChangeNotifier {
  final IAuthRepository _repo;
  Student? _currentUser;
  bool _isLoading = true;
  bool _isAuthUpdateRequired = false;
  bool _isStaffOAuthLoading = false;

  AuthProvider(this._repo) {
    loadUser();
    _initDataServiceListener();
  }

  Student? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAuthUpdateRequired => _isAuthUpdateRequired;
  bool get isStaffOAuthLoading => _isStaffOAuthLoading;
  
  bool get isTutor => _currentUser?.role == 'tyutor' || _currentUser?.staffRole == 'tyutor';
  bool get isManagement {
    final role = _currentUser?.role?.toLowerCase();
    final staffRole = _currentUser?.staffRole?.toLowerCase();
    final mgmtRoles = ['rahbariyat', 'dekan', 'dekan_orinbosari', 'dekan_yoshlar', 'dekanat', 'owner', 'developer'];
    return mgmtRoles.contains(role) || mgmtRoles.contains(staffRole);
  }

  void _initDataServiceListener() {
    DataService.onAuthError = (errorType) {
      // [FIXED] Handle all types of auth errors (including session expired)
      _isAuthUpdateRequired = true;
      notifyListeners();
    };
  }
  
  void resetAuthUpdateRequired() {
    _isAuthUpdateRequired = false;
    notifyListeners();
  }

  Future<void> loadUser() async {
    try {
      _currentUser = await _repo.getSavedUser();
    } catch (e) {
      debugPrint("AuthProvider: Error loading user (possible offline): $e");
      // [FIXED] Don't logout automatically here, as it might just be a network error
      // The cached user from repository should be enough to keep the session alive
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String login, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final student = await _repo.login(login, password);
      if (student != null) {
        _currentUser = student;
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _isLoading = false;
        notifyListeners();
        return "Login yoki parol xato";
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return _mapErrorToMessage(e.toString());
    }
  }

  Future<String?> loginWithToken(String token) async {
    _isLoading = true;
    _isStaffOAuthLoading = true;
    notifyListeners();

    try {
      final student = await _repo.loginWithToken(token);
      if (student != null) {
        _currentUser = student;
        _isLoading = false;
        _isStaffOAuthLoading = false;
        notifyListeners();
        return null;
      } else {
        _isLoading = false;
        _isStaffOAuthLoading = false;
        notifyListeners();
        return "Tizimga kirishda xatolik (Token yaroqsiz)";
      }
    } catch (e) {
      _isLoading = false;
      _isStaffOAuthLoading = false;
      notifyListeners();
      return "Xatolik: $e";
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _currentUser = null;
    notifyListeners();
  }

  String _mapErrorToMessage(String errorMsg) {
    if (errorMsg.contains("RATE_LIMIT")) {
      return "Siz qisqa vaqt ichida ko'p marta xato kiritdingiz.\nIltimos 2 daqiqadan so'ng urinib ko'ring.";
    } else if (errorMsg.contains("DB_ERROR")) {
      return "Tizimda vaqtincha nosozlik (Baza).\nBirozdan so'ng qayta urinib ko'ring.";
    } else if (errorMsg.contains("HEMIS_ERROR")) {
      return "Universitet HEMIS tizimi ishlamayapti.\nBu bizga bog'liq emas, keyinroq kiring.";
    } else if (errorMsg.contains("INVALID_CREDENTIALS") || errorMsg.toLowerCase().contains("login yoki parol")) {
      return "Login yoki parol xato!";
    }
    return "Xatolik: ${errorMsg.replaceAll("Exception:", "").trim()}";
  }
}
