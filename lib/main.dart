import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:talabahamkor_mobile/features/shared/auth/auth_provider.dart';
import 'package:talabahamkor_mobile/core/providers/notification_provider.dart';
import 'package:talabahamkor_mobile/core/providers/locale_provider.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';
import 'package:talabahamkor_mobile/features/shared/auth/screens/login_screen.dart';
import 'package:talabahamkor_mobile/features/home/screens/home_screen.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'package:talabahamkor_mobile/core/services/push_notification_service.dart';
import 'package:talabahamkor_mobile/core/auth/hemis_auth_repo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:talabahamkor_mobile/core/network/api_client.dart';
import 'package:talabahamkor_mobile/core/network/direct_http_overrides.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    PushNotificationService.initialize(); 
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  HttpOverrides.global = DirectHttpOverrides(); 
  
  final dio = Dio();
  final apiClient = ApiClient(dio);
  final dataService = DataService(apiClient);
  final userRepo = HemisAuthRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthProvider(userRepo)),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        Provider.value(value: dataService),
      ],
      child: const TalabaHamkorApp(),
    ),
  );
}

class TalabaHamkorApp extends StatefulWidget {
  const TalabaHamkorApp({super.key});

  @override
  State<TalabaHamkorApp> createState() => _TalabaHamkorAppState();
}

class _TalabaHamkorAppState extends State<TalabaHamkorApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep Link Stream Error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'talabahamkor' && (uri.host == 'login' || uri.host == 'auth')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        if (mounted) {
           final auth = Provider.of<AuthProvider>(context, listen: false);
           auth.loginWithToken(token).then((error) async {
             if (error == null) {
                final user = auth.currentUser;
                if (user != null) {
                  final isStudentBase = (user.role == 'student' || user.role == 'yetakchi');
                  final rolePrefix = isStudentBase ? 'student' : 'staff';
                  final link = 'https://t.me/talabahamkorbot?start=login__${rolePrefix}_id_${user.id}';
                  final uri = Uri.parse(link);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint("URL launch error: $e");
                  }
                }
             }
           });
        }
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
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        if (!localeProvider.isLoaded) {
           return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'tengdosh',
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('uz', 'UZ'), 
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: localeProvider.locale,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
          if (auth.isLoading) {
             return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (auth.isAuthenticated) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
      },
    );
  }
}