import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talabahamkor_mobile/features/shared/auth/auth_provider.dart';
import '../../features/shared/auth/screens/one_id_webview_screen.dart';
import '../../features/pro/dashboard/providers/pro_dashboard_provider.dart';
import '../../features/pro/scoring/screens/pending_reviews_screen.dart';
import '../../features/pro/attendance/screens/qr_scanner_screen.dart';

class ProApp extends StatelessWidget {
  const ProApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFD40405);

    return MaterialApp(
      title: 'Tengdosh Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandRed, 
          primary: brandRed,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.white,
        ),
      ),
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
    final dashboard = Provider.of<ProDashboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    const Color brandRed = Color(0xFFD40405);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tengdosh Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(user?.universityName ?? 'University Management', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboard.fetchStats(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xush kelibsiz, ${user?.fullName.split(' ').first ?? 'Xodim'}!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Statistics Grid (Professional Style)
              const Text('Asosiy statistika', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Talabalar', dashboard.studentCount.toString(), Icons.group_outlined, brandRed),
                  _buildStatCard('Kutilmoqda', dashboard.pendingAppeals.toString(), Icons.hourglass_empty, Colors.orange),
                  _buildStatCard('Haftalik', '124', Icons.assessment_outlined, Colors.blue),
                  _buildStatCard('Grantlar', '84%', Icons.verified_user_outlined, Colors.green),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text('Haftalik faollik tahlili', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Custom Activity Chart Placeholder
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [0.3, 0.5, 0.8, 0.4, 0.9, 0.6, 0.7].map((h) => Container(
                    width: 25,
                    height: 140 * h,
                    decoration: BoxDecoration(
                      color: brandRed.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
      
      // Floating Action Center
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'qr',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen())),
                backgroundColor: brandRed,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR Davomat'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'review',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingReviewsScreen())),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.rate_review),
                label: const Text('Arizalar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class ProLoginScreen extends StatelessWidget {
  const ProLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandRed = Color(0xFFD40405);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle gradient or pattern could go here
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // App Logo (Matching Tengdosh style)
                  Center(
                    child: Hero(
                      tag: 'pro_logo',
                      child: Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: brandRed.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: brandRed, size: 60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "tengdosh",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42, 
                      fontWeight: FontWeight.w900, 
                      color: brandRed,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    "PRO MANAGEMENT",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.grey,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Main Info Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Xodimlar uchun kirish",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Universitet boshqaruv tizimiga kirish uchun OneID identifikatsiya xizmatidan foydalaning",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const OneIdWebViewScreen()),
                              );
                            },
                            icon: const Icon(Icons.security_rounded),
                            label: const Text('Login with OneID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: brandRed.withOpacity(0.4),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        // DEBUG BUTTON (Moved inside the styled container)
                        TextButton(
                          onPressed: () async {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            await auth.loginWithToken("DEBUG_TOKEN_PRO");
                          },
                          child: const Text(
                            "DEBUG MODE: KIRISH (BYPASS)", 
                            style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  const Text(
                    "Faqat vakolatli xodimlar uchun.\nBarcha harakatlar tizimda qayd etiladi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
