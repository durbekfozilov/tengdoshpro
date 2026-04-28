import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'pro_app.dart';
import '../../core/network/api_client.dart';
import '../../core/network/data_service.dart';
import '../../features/shared/auth/auth_provider.dart';
import '../../core/auth/one_id_auth_repo.dart';
import '../../features/pro/dashboard/providers/pro_dashboard_provider.dart';
import '../../features/pro/scoring/providers/scoring_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio();
  final apiClient = ApiClient(dio);
  final dataService = DataService(apiClient);
  
  // Strategy: OneID for Pro App
  final proRepo = OneIdAuthRepository(dataService);

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
