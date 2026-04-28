import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/data_service.dart';
import '../../features/shared/auth/auth_provider.dart';
import '../../features/pro/dashboard/providers/pro_dashboard_provider.dart';
import '../../features/pro/scoring/providers/scoring_provider.dart';
import '../../core/auth/base_auth_repo.dart';
import 'pro_app.dart';

// Placeholder for the actual OneID implementation
class OneIdAuthRepository implements IAuthRepository {
  @override
  Future<bool> checkUsernameAvailability(String username) async => true;
  @override
  Future<dynamic> getSavedUser() async => null;
  @override
  Future<dynamic> login(String login, String password) async => null;
  @override
  Future<dynamic> loginWithToken(String token) async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<Map<String, dynamic>> setUsername(String username) async => {'success': true};
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio();
  final apiClient = ApiClient(dio);
  final dataService = DataService(apiClient);
  final proRepo = OneIdAuthRepository();
  
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: dataService),
        ChangeNotifierProvider(create: (_) => AuthProvider(proRepo)),
        ChangeNotifierProvider(create: (_) => ProDashboardProvider(dataService)),
        ChangeNotifierProvider(create: (_) => ScoringProvider(dataService)),
      ],
      child: const ProApp(),
    ),
  );
}
