import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talabahamkor_mobile/features/shared/auth/auth_provider.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'package:talabahamkor_mobile/features/pro/dashboard/providers/pro_dashboard_provider.dart';
import 'package:talabahamkor_mobile/features/tutor/screens/tutor_dashboard_screen.dart';
import 'package:talabahamkor_mobile/features/home/widgets/management_dashboard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:talabahamkor_mobile/core/constants/api_constants.dart';

class ProApp extends StatelessWidget {
  const ProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tengdosh Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (auth.isAuthenticated) {
            return const ProDashboard();
          }
          return const ProLoginScreen();
        },
      ),
    );
  }
}

class ProDashboard extends StatelessWidget {
  const ProDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final dashboard = Provider.of<ProDashboardProvider>(context);
    final user = auth.currentUser;

    if (dashboard.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Role-based Dispatcher
    Widget dashboardBody;
    String roleTitle = "Boshqaruv";

    final String role = (user?.staffRole ?? user?.role ?? "").toLowerCase();

    if (role.contains("tutor") || role.contains("tyutor")) {
      dashboardBody = TutorDashboardScreen(stats: dashboard.stats);
      roleTitle = "Tyutor Paneli";
    } else {
      // Default to Management Dashboard for Dekan, Rektor, etc.
      dashboardBody = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ManagementDashboard(stats: dashboard.stats),
      );
      roleTitle = "Rahbariyat Paneli";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              roleTitle,
              style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.universityName ?? "Tengdosh Pro",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: dashboardBody,
    );
  }
}

class ProLoginScreen extends StatelessWidget {
  const ProLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandRed = Color(0xFFE31E24);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // Logo
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: brandRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              "Tengdosh Pro",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: brandRed,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Staff & Management Portal",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const Spacer(flex: 2),

            // Login Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  // Main OneID Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse('${ApiConstants.oauthLogin}?source=mobile&role=staff');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint("OneID launch error: $e");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: brandRed.withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Login with OneID',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Developer Bypass Button
                  TextButton(
                    onPressed: () => Provider.of<AuthProvider>(context, listen: false)
                        .loginWithToken("DEBUG_TOKEN_PRO"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.developer_mode, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        const Text(
                          "Developer Entry (Bypass)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            const Text(
              "Authorized access only",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
