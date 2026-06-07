import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import 'login_screen.dart';
import 'attendance_screen.dart';
import 'staff_complaint_form_page.dart';
import 'staff/staff_directory_screen.dart';
import 'my_rota_screen.dart';
import 'news_screen.dart';
import 'maintenance/add_maintenance_screen.dart';
import 'maintenance/maintenance_home_screen.dart';
import 'kitchen/kitchen_inventory_screen.dart';
import 'housekeeping/hk_my_rooms_screen.dart';
import 'housekeeping/hk_supervisor_progress_screen.dart';
import 'housekeeping/hk_inspection_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String name = '';
  String email = '';
  String department = '';
  String role = '';
  String token = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        name = prefs.getString('userName') ?? 'User';
        email = prefs.getString('userEmail') ?? '';
        department = prefs.getString('department') ?? '';
        role = prefs.getString('role') ?? '';
        token = prefs.getString('token') ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKitchenAccess = department.toLowerCase() == 'kitchen' &&
        ['supervisor', 'chef', 'head-chef'].contains(role.toLowerCase());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          isLoading
                              ? 'Loading...'
                              : 'Hello, ${name.split(' ').first} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          department.isEmpty
                              ? 'Welcome back to the dashboard'
                              : department,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(context, isKitchenAccess),

                const SizedBox(height: 32),

                _buildSectionHeader('Manage'),
                const SizedBox(height: 16),
                _buildFeatureCards(context),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xff1f2937),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isKitchenAccess) {
    final normalizedDepartment = department.toLowerCase().trim();

    final isHousekeepingAccess =
        normalizedDepartment == 'housekeeping' ||
        normalizedDepartment == 'hk' ||
        normalizedDepartment == 'house keeping';

    final isHkSupervisor = isHousekeepingAccess &&
    role.toLowerCase().trim() == 'supervisor';

    final actions = [
      _ActionItem(
        icon: Icons.people_outline,
        title: 'Staff Directory',
        color: const Color(0xff6366f1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StaffDirectoryScreen()),
        ),
      ),
      _ActionItem(
        icon: Icons.calendar_month_outlined,
        title: 'My Rota',
        color: const Color(0xff10b981),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyRotaScreen()),
        ),
      ),
      _ActionItem(
        icon: Icons.access_time,
        title: 'Attendance',
        color: const Color(0xff06b6d4),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceQrScannerPage(authToken: token),
          ),
        ),
      ),
    ];

    if (isHousekeepingAccess) {
      actions.add(
        _ActionItem(
          icon: Icons.cleaning_services_outlined,
          title: 'My Rooms',
          color: const Color(0xff14b8a6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HkMyRoomsScreen(),
            ),
          ),
        ),
      );
    }

  if (isHkSupervisor) {
  actions.add(
    _ActionItem(
      icon: Icons.dashboard_customize_outlined,
      title: 'HK Progress',
      color: const Color(0xff0f766e),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HkSupervisorProgressScreen(),
        ),
      ),
    ),
  );

  actions.add(
    _ActionItem(
      icon: Icons.fact_check_outlined,
      title: 'HK Inspection',
      color: const Color(0xff059669),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HkInspectionScreen(),
        ),
      ),
    ),
  );
}
    actions.addAll([
      _ActionItem(
        icon: Icons.newspaper_outlined,
        title: 'News',
        color: const Color(0xfff59e0b),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewsScreen()),
        ),
      ),
      _ActionItem(
        icon: Icons.build_outlined,
        title: 'Maintenance',
        color: const Color(0xffef4444),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMaintenanceScreen()),
        ),
      ),
      _ActionItem(
        icon: Icons.report_problem,
        title: 'Complaint',
        color: const Color(0xffec4899),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffComplaintFormPage(authToken: token),
          ),
        ),
      ),
    ]);

    if (isKitchenAccess) {
      actions.add(
        _ActionItem(
          icon: Icons.inventory_2_outlined,
          title: 'Inventory',
          color: const Color(0xff8b5cf6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KitchenInventoryScreen()),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) crossAxisCount = 3;
        if (constraints.maxWidth > 900) crossAxisCount = 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _buildModernCard(actions[index]),
        );
      },
    );
  }

  Widget _buildModernCard(_ActionItem action) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, color: action.color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.construction_outlined,
          title: 'Maintenance Jobs',
          subtitle: 'View and track all maintenance tasks',
          color: const Color(0xFF6366F1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaintenanceHomeScreen()),
          ),
        ),
        _buildListTile(
          icon: Icons.analytics_outlined,
          title: 'Reports',
          subtitle: 'View attendance and performance reports',
          color: const Color(0xFF10B981),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reports feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}