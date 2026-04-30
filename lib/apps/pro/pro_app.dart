import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talabahamkor_mobile/features/shared/auth/auth_provider.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'package:talabahamkor_mobile/features/shared/auth/screens/one_id_webview_screen.dart';
import 'package:talabahamkor_mobile/features/pro/dashboard/providers/pro_dashboard_provider.dart';
import 'package:talabahamkor_mobile/features/pro/scoring/screens/pending_reviews_screen.dart';
import 'package:talabahamkor_mobile/features/pro/attendance/screens/qr_scanner_screen.dart';
import 'package:talabahamkor_mobile/features/management/screens/management_appeals_screen.dart';

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
    final dashboard = Provider.of<ProDashboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final primaryColor = Theme.of(context).primaryColor;

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
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    context, 
                    'Talabalar', 
                    dashboard.studentCount.toString(), 
                    Icons.group_outlined, 
                    primaryColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Talabalar ro'yxati yuklanmoqda...")));
                    },
                  ),
                  _buildStatCard(
                    context,
                    'Kutilmoqda', 
                    dashboard.pendingAppeals.toString(), 
                    Icons.hourglass_empty, 
                    Colors.orange,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingReviewsScreen()));
                    },
                  ),
                  _buildStatCard(
                    context,
                    'Haftalik', 
                    '124', 
                    Icons.assessment_outlined, 
                    Colors.blue,
                    onTap: () {
                      // Weekly Analytics
                    },
                  ),
                  _buildStatCard(
                    context,
                    'Grantlar', 
                    '84%', 
                    Icons.verified_user_outlined, 
                    AppTheme.accentGreen,
                    onTap: () {
                      // Grants view
                    },
                  ),
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
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [0.3, 0.5, 0.8, 0.4, 0.9, 0.6, 0.7].map((h) => Container(
                    width: 25,
                    height: 140 * h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
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
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR Davomat'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'review',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagementAppealsScreen())),
                backgroundColor: AppTheme.textBlack,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.rate_review),
                label: const Text('Arizalar'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProLoginScreen extends StatelessWidget {
  const ProLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use const to avoid theme color override
    const primaryColor = AppTheme.primaryBlue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft background circles
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 64),

                  // Logo
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: primaryColor,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Brand
                  const Text(
                    "tengdosh",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const Text(
                    "PRO MANAGEMENT",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.10),
                          blurRadius: 36,
                          offset: const Offset(0, 16),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Xodimlar uchun kirish",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Universitet boshqaruv tizimiga kirish uchun\nOneID xizmatidan foydalaning",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // OneID Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OneIdWebViewScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                            label: const Text(
                              'Login with OneID',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 44),
                  Text(
                    "Faqat vakolatli xodimlar uchun.\nBarcha harakatlar tizimda xavfsizlik maqsadida qayd etiladi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


