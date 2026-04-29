import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'pro_app.dart';
import 'package:talabahamkor_mobile/core/network/api_client.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';
import 'package:talabahamkor_mobile/features/shared/auth/auth_provider.dart';
import 'package:talabahamkor_mobile/core/auth/one_id_auth_repo.dart';
import 'package:talabahamkor_mobile/features/pro/dashboard/providers/pro_dashboard_provider.dart';
import 'package:talabahamkor_mobile/features/pro/scoring/providers/scoring_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = Dio();
  final apiClient = ApiClient(dio);
  // Initialize the DataService singleton with the configured ApiClient
  final dataService = DataService(apiClient);

  // Pro App uses OneID authentication
  final proRepo = OneIdAuthRepository(dataService);
  final authProvider = AuthProvider(proRepo);
  // No debug bypass — app will show ProLoginScreen if not authenticated

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: dataService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProDashboardProvider(dataService)),
        ChangeNotifierProvider(create: (_) => ScoringProvider(dataService)),
      ],
      child: const ProApp(),
    ),
  );
}
