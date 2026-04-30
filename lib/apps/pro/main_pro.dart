import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'pro_app.dart';
import 'package:talabahamkor_mobile/core/network/api_client.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';
import 'package:talabahamkor_mobile/features/shared/auth/auth_provider.dart';
import 'package:talabahamkor_mobile/core/auth/one_id_auth_repo.dart';
import 'package:talabahamkor_mobile/features/pro/dashboard/providers/pro_dashboard_provider.dart';
import 'package:talabahamkor_mobile/features/pro/scoring/providers/scoring_provider.dart';
import 'package:talabahamkor_mobile/core/providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = Dio();
  final apiClient = ApiClient(dio);
  final dataService = DataService(apiClient);

  final proRepo = OneIdAuthRepository(dataService);
  final authProvider = AuthProvider(proRepo);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: dataService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ProDashboardProvider(dataService)),
        ChangeNotifierProvider(create: (_) => ScoringProvider(dataService)),
      ],
      child: const ProAppWithDeepLinks(),
    ),
  );
}

class ProAppWithDeepLinks extends StatefulWidget {
  const ProAppWithDeepLinks({super.key});

  @override
  State<ProAppWithDeepLinks> createState() => _ProAppWithDeepLinksState();
}

class _ProAppWithDeepLinksState extends State<ProAppWithDeepLinks> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'talabahamkor' && (uri.host == 'login' || uri.host == 'auth')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.loginWithToken(token);
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const ProApp();
  }
}
