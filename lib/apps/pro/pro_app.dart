import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/shared/auth/auth_provider.dart';
import '../../features/shared/auth/screens/one_id_webview_screen.dart';
import '../../features/pro/dashboard/providers/pro_dashboard_provider.dart';
import '../../features/pro/scoring/screens/pending_reviews_screen.dart';
import '../../features/pro/attendance/screens/qr_scanner_screen.dart';
import '../../features/pro/notifications/screens/send_notification_screen.dart';

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
                'Xush kelibsiz, ${user?.name?.split(' ').first ?? 'Xodim'}!',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: brandRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 32),
              const Text(
                "Tengdosh Pro",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: brandRed),
              ),
              const Text(
                "Staff & Management Portal",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OneIdWebViewScreen()),
                    );
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Login with OneID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: brandRed.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Authorized access only",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
