import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';
import 'screens/attendance_screen.dart';
import 'package:app_links/app_links.dart';
import 'screens/reset_password_screen.dart';
import 'screens/forgot_password_screen.dart';
const String baseUrl = 'https://mgmglasgow.com/api';
// const String baseUrl = 'http://192.168.0.10:8000/api';

/* ================= APP CONFIG ================= */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MgmOpsApp());
}

class MgmOpsApp extends StatefulWidget {
  const MgmOpsApp({super.key});

  @override
  State<MgmOpsApp> createState() => _MgmOpsAppState();
}

class _MgmOpsAppState extends State<MgmOpsApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks appLinks;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    appLinks = AppLinks();

    appLinks.uriLinkStream.listen((Uri uri) {
      handleDeepLink(uri);
    });
  }

  void handleDeepLink(Uri uri) {
    if (uri.scheme == 'mgmops' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];

      if (token != null && email != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: token,
              email: email,
            ),
          ),
        );
      }

      if (uri.scheme == 'mgmops' && uri.host == 'login') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MGM Ops',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff1583ff),
          brightness: Brightness.light,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

/* ================= COLOR PALETTE ================= */

class AppColors {
  static const primary = Color(0xff1583ff);
  static const secondary = Color(0xffff15c4);
  static const background = Color(0xfff5f7fa);
  static const cardBg = Colors.white;
  static const success = Color(0xff22c55e);
  static const warning = Color(0xfff59e0b);
  static const danger = Color(0xffef4444);
  static const grey = Color(0xff6b7280);
  static const lightGrey = Color(0xfff3f4f6);
}

/* ================= LOGIN SCREEN ================= */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userName', data['user']['name'] ?? '');
        await prefs.setString('userEmail', data['user']['email'] ?? '');
        await prefs.setString('department', data['user']['department']?['name'] ?? '');
        await prefs.setString('role', data['user']['role']?['name'] ?? '');

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Branding
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'MGM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'MGM Ops',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email Field
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= DASHBOARD SCREEN ================= */

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

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('userName') ?? '';
      email = prefs.getString('userEmail') ?? '';
      department = prefs.getString('department') ?? '';
      role = prefs.getString('role') ?? '';
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKitchenAccess = department.toLowerCase() == 'kitchen' &&
        ['supervisor', 'chef'].contains(role.toLowerCase());

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 120,
              backgroundColor: AppColors.primary,
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Hello, $name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            department.isEmpty ? 'Welcome back!' : department,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Actions Section
                  _buildSectionHeader('Quick Actions'),
                  const SizedBox(height: 12),

                  _buildQuickActionsGrid(context, isKitchenAccess),

                  const SizedBox(height: 24),

                  // Recent Activity Section
                  _buildSectionHeader('Features'),
                  const SizedBox(height: 12),

                  _buildFeatureCards(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xff1f2937),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isKitchenAccess) {
    final actions = [
      _ActionItem(
        icon: Icons.people_outline,
        title: 'Staff Directory',
        color: const Color(0xff6366f1),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffDirectoryScreen())),
      ),
      _ActionItem(
        icon: Icons.calendar_month_outlined,
        title: 'My Rota',
        color: const Color(0xff10b981),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRotaScreen())),
      ),

      //attencence screen
      _ActionItem(
            icon: Icons.access_time,
            title: 'Attendance',
            color: const Color(0xff06b6d4),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceScreen()),
            ),
          ),

      _ActionItem(
        icon: Icons.newspaper_outlined,
        title: 'News',
        color: const Color(0xfff59e0b),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())),
      ),
      _ActionItem(
        icon: Icons.build_outlined,
        title: 'Add Maintenance',
        color: const Color(0xffef4444),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMaintenanceScreen())),
      ),
    ];

    if (isKitchenAccess) {
      actions.add(_ActionItem(
        icon: Icons.inventory_2_outlined,
        title: 'Kitchen Inventory',
        color: const Color(0xff8b5cf6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenInventoryScreen())),
      ));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _buildQuickActionCard(actions[index]),
        );
      },
    );
  }

  Widget _buildQuickActionCard(_ActionItem action) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        _FeatureCard(
          icon: Icons.construction_outlined,
          title: 'Maintenance Jobs',
          subtitle: 'View and track all maintenance tasks',
          color: const Color(0xffec4899),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceHomeScreen ())),
        ),
      ],
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= MAINTENANCE HOME SCREEN ================= */

class MaintenanceHomeScreen extends StatelessWidget {
  const MaintenanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Maintenance Jobs'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ActiveMaintenanceTab(),
            PastMaintenanceTab(),
          ],
        ),
      ),
    );
  }
}

/* ================= ACTIVE MAINTENANCE TAB ================= */

class ActiveMaintenanceTab extends StatefulWidget {
  const ActiveMaintenanceTab({super.key});

  @override
  State<ActiveMaintenanceTab> createState() => _ActiveMaintenanceTabState();
}

class _ActiveMaintenanceTabState extends State<ActiveMaintenanceTab> {
  bool isLoading = true;
  List activeJobs = [];

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance/jobs'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final allJobs = List<Map<String, dynamic>>.from(data['jobs']);

        // Filter active jobs (pending, in_progress only)
        setState(() {
          activeJobs = allJobs.where((job) {
            final status = job['status']?.toString().toLowerCase();
            return status == 'pending' || status == 'in_progress';
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeJobs.isEmpty
              ? _EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No Active Jobs',
                  subtitle: 'All maintenance jobs are up to date',
                )
              : RefreshIndicator(
                  onRefresh: fetchJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeJobs.length,
                    itemBuilder: (context, index) {
                      final job = activeJobs[index];
                      return _JobCard(
                        job: job,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaintenanceJobDetailScreen(job: job),
                            ),
                          ).then((_) => fetchJobs());
                        },
                        priorityColor: priorityColor,
                        statusColor: statusColor,
                      );
                    },
                  ),
                ),
    );
  }
}

/* ================= PAST MAINTENANCE TAB ================= */

class PastMaintenanceTab extends StatefulWidget {
  const PastMaintenanceTab({super.key});

  @override
  State<PastMaintenanceTab> createState() => _PastMaintenanceTabState();
}

class _PastMaintenanceTabState extends State<PastMaintenanceTab> {
  bool isLoading = true;
  List pastJobs = [];

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance/jobs'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final allJobs = List<Map<String, dynamic>>.from(data['jobs']);

        // Filter past jobs (completed, cancelled only)
        setState(() {
          pastJobs = allJobs.where((job) {
            final status = job['status']?.toString().toLowerCase();
            return status == 'completed' || status == 'cancelled';
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pastJobs.isEmpty
              ? _EmptyState(
                  icon: Icons.history,
                  title: 'No Past Jobs',
                  subtitle: 'Completed and cancelled jobs will appear here',
                )
              : RefreshIndicator(
                  onRefresh: fetchJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pastJobs.length,
                    itemBuilder: (context, index) {
                      final job = pastJobs[index];
                      return _JobCard(
                        job: job,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaintenanceJobDetailScreen(job: job),
                            ),
                          ).then((_) => fetchJobs());
                        },
                        priorityColor: priorityColor,
                        statusColor: statusColor,
                      );
                    },
                  ),
                ),
    );
  }
}

/* ================= EMPTY STATE WIDGET ================= */

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= JOB CARD WIDGET ================= */

class _JobCard extends StatelessWidget {
  final Map job;
  final VoidCallback onTap;
  final Color Function(String) priorityColor;
  final Color Function(String) statusColor;

  const _JobCard({
    required this.job,
    required this.onTap,
    required this.priorityColor,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (job['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    job['image_url'],
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              if (job['image_url'] != null) const SizedBox(height: 12),
              Text(
                job['title'] ?? 'No Title',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                job['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.grey, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(
                    text: (job['priority'] ?? '').replaceAll('_', ' ').toUpperCase(),
                    color: priorityColor(job['priority'] ?? ''),
                  ),
                  _Badge(
                    text: (job['status'] ?? '').replaceAll('_', ' ').toUpperCase(),
                    color: statusColor(job['status'] ?? ''),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${job['location'] ?? 'N/A'} | Room: ${job['room_number'] ?? 'N/A'}',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= BADGE WIDGET ================= */

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}



/* ================= MAINTENANCE JOB DETAIL SCREEN ================= */

class MaintenanceJobDetailScreen extends StatefulWidget {
  final Map job;

  const MaintenanceJobDetailScreen({super.key, required this.job});

  @override
  State<MaintenanceJobDetailScreen> createState() =>
      _MaintenanceJobDetailScreenState();
}

class _MaintenanceJobDetailScreenState
    extends State<MaintenanceJobDetailScreen> {
  late String status;
  late TextEditingController noteController;
  bool isUpdating = false;
  String department = '';

  @override
  void initState() {
    super.initState();
    status = widget.job['status'] ?? 'pending';
    noteController = TextEditingController(text: widget.job['note'] ?? '');
    loadUserDepartment();
  }

  Future<void> loadUserDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      department = prefs.getString('department') ?? '';
    });
  }

  Future<void> updateStatus() async {
    setState(() => isUpdating = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/maintenance/jobs/${widget.job['id']}/status'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {'status': status},
    );

    final data = jsonDecode(response.body);
    setState(() => isUpdating = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Status updated')),
    );
  }

  Future<void> updateNote() async {
    setState(() => isUpdating = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/maintenance/jobs/${widget.job['id']}/note'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {'note': noteController.text},
    );

    final data = jsonDecode(response.body);
    setState(() => isUpdating = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Note updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMaintenance = department == 'Maintenance';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.job['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.job['image_url'],
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            if (widget.job['image_url'] != null) const SizedBox(height: 16),

            _DetailCard(
              children: [
                Text(
                  widget.job['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.job['description'] ?? '',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const Divider(height: 24),
                _InfoRow('Priority', (widget.job['priority'] ?? 'N/A').toUpperCase()),
                _InfoRow('Status', (widget.job['status'] ?? 'N/A').replaceAll('_', ' ').toUpperCase()),
                _InfoRow('Location', widget.job['location'] ?? 'N/A'),
                _InfoRow('Room', widget.job['room_number'] ?? 'N/A'),
                _InfoRow('Reported By', widget.job['reporter']?['name'] ?? 'N/A'),
                _InfoRow('Assigned To', widget.job['assigned_user']?['name'] ?? 'Not Assigned'),
              ],
            ),

            const SizedBox(height: 16),

            _DetailCard(
              children: [
                const Text(
                  'Maintenance Note',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  enabled: isMaintenance,
                  decoration: InputDecoration(
                    hintText: 'Add maintenance note...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                if (isMaintenance) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isUpdating ? null : updateNote,
                      icon: const Icon(Icons.save),
                      label: const Text('Update Note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (isMaintenance) ...[
              const SizedBox(height: 16),
              _DetailCard(
                children: [
                  const Text(
                    'Update Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isUpdating ? null : updateStatus,
                      icon: const Icon(Icons.update),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= ADD MAINTENANCE SCREEN ================= */

class AddMaintenanceScreen extends StatefulWidget {
  const AddMaintenanceScreen({super.key});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  XFile? selectedImage;
  final ImagePicker picker = ImagePicker();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final roomController = TextEditingController();

  bool isLoading = false;
  bool isDepartmentLoading = true;

  List departments = [];
  String? selectedDepartment;
  String priority = 'medium';

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 75,
                      maxWidth: 1280,
                      maxHeight: 1280,
                    );
                    if (image != null) setState(() => selectedImage = image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 75,
                      maxWidth: 1280,
                      maxHeight: 1280,
                    );
                    if (image != null) setState(() => selectedImage = image);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

   Future<void> fetchDepartments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/departments'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        departments = data['departments'];
        isDepartmentLoading = false;
      });
    } else {
      setState(() => isDepartmentLoading = false);
    }
  }

  Future<void> submitTask() async {
    if (selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select department')),
      );
      return;
    }

    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter task title')),
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/maintenance/jobs'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['department_id'] = selectedDepartment!;
    request.fields['title'] = titleController.text.trim();
    request.fields['description'] = descriptionController.text.trim();
    request.fields['location'] = locationController.text.trim();
    request.fields['room_number'] = roomController.text.trim();
    request.fields['priority'] = priority;

    if (selectedImage != null) {
      final imageBytes = await selectedImage!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: selectedImage!.name,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    setState(() => isLoading = false);

    if (!mounted) return;

    if (response.statusCode == 201 && data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Task added successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to add task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Maintenance Task'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isDepartmentLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Maintenance Task',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to submit a new task',
                        style: TextStyle(color: AppColors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Department
                      DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: departments.map<DropdownMenuItem<String>>((dept) {
                          return DropdownMenuItem<String>(
                            value: dept['id'].toString(),
                            child: Text(dept['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedDepartment = value);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Priority
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => priority = value);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Location
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Room Number
                      TextField(
                        controller: roomController,
                        decoration: const InputDecoration(
                          labelText: 'Room Number',
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Image Upload
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 40,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedImage == null
                                    ? 'Tap to upload image'
                                    : selectedImage!.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : submitTask,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Submit Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/* ================= NEWS SCREEN ================= */

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool isLoading = true;
  List news = [];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/news'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          news = data['news'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News & Blogs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : news.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No news available',
                        style: TextStyle(color: AppColors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchNews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: news.length,
                    itemBuilder: (context, index) {
                      final item = news[index];
                      return _NewsCard(
                        news: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewsDetailScreen(news: item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map news;
  final VoidCallback onTap;

  const _NewsCard({required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news['image_url'] != null)
                Image.network(
                  news['image_url'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news['description'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: AppColors.grey),
                        const SizedBox(width: 6),
                        Text(
                          (news['created_at'] ?? '').toString().substring(0, 10),
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= NEWS DETAIL SCREEN ================= */

class NewsDetailScreen extends StatelessWidget {
  final Map news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news['image_url'] != null)
              Image.network(
                news['image_url'],
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.grey),
                      const SizedBox(width: 6),
                      Text(
                        (news['created_at'] ?? '').toString().substring(0, 10),
                        style: TextStyle(color: AppColors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    news['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Color(0xff374151),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= STAFF DIRECTORY SCREEN ================= */

class StaffDirectoryScreen extends StatelessWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Staff Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your staff options and requests',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StaffOption(
            icon: Icons.calendar_month_outlined,
            title: 'Apply Holiday',
            subtitle: 'Submit a new holiday request',
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyHolidayScreen())),
          ),
          _StaffOption(
            icon: Icons.history,
            title: 'Past Holidays',
            subtitle: 'View your holiday request history',
            color: AppColors.warning,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyHolidayRequestsScreen())),
          ),
          _StaffOption(
            icon: Icons.lock_reset,
            title: 'Change Password',
            subtitle: 'Update your account password',
            color: AppColors.success,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          _StaffOption(
            icon: Icons.person_outline,
            title: 'My Profile',
            subtitle: 'View and update your profile',
            color: AppColors.secondary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProfileScreen())),
          ),
        ],
      ),
    );
  }
}

class _StaffOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StaffOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= APPLY HOLIDAY SCREEN ================= */

class ApplyHolidayScreen extends StatefulWidget {
  const ApplyHolidayScreen({super.key});

  @override
  State<ApplyHolidayScreen> createState() => _ApplyHolidayScreenState();
}

class _ApplyHolidayScreenState extends State<ApplyHolidayScreen> {
  DateTime? startDate;
  DateTime? endDate;
    final reasonController = TextEditingController();
  bool isLoading = false;

  Future<void> pickDate({required bool isStart}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          startDate = pickedDate;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          endDate = pickedDate;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> submitHoliday() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end date')),
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/holiday-requests'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
        'reason': reasonController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (!mounted) return;

    if (response.statusCode == 201 && data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Holiday request submitted')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to submit request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = startDate != null && endDate != null
        ? endDate!.difference(startDate!).inDays + 1
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Holiday'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Holiday Request',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your holiday dates and submit your request',
                style: TextStyle(color: AppColors.grey),
              ),
              const SizedBox(height: 24),

              // Start Date
              _DatePickerBox(
                title: 'Start Date',
                value: formatDate(startDate),
                onTap: () => pickDate(isStart: true),
              ),
              const SizedBox(height: 14),

              // End Date
              _DatePickerBox(
                title: 'End Date',
                value: formatDate(endDate),
                onTap: () => pickDate(isStart: false),
              ),
              const SizedBox(height: 14),

              // Total Days
              if (totalDays > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total Days: $totalDays',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Reason
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Reason (Optional)',
                  hintText: 'Enter reason for your holiday',
                  prefixIcon: const Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : submitHoliday,
                  icon: const Icon(Icons.send),
                  label: isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Submit Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerBox extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DatePickerBox({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= MY HOLIDAY REQUESTS SCREEN ================= */

class MyHolidayRequestsScreen extends StatefulWidget {
  const MyHolidayRequestsScreen({super.key});

  @override
  State<MyHolidayRequestsScreen> createState() => _MyHolidayRequestsScreenState();
}

class _MyHolidayRequestsScreenState extends State<MyHolidayRequestsScreen> {
  bool isLoading = true;
  List requests = [];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-holiday-requests'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          requests = data['requests'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteHolidayRequest(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/holiday-requests/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Deleted')),
      );

      fetchRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Holiday Requests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No holiday requests found',
                        style: TextStyle(color: AppColors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final isPending = request['status'] == 'pending';

                      final card = _HolidayRequestCard(
                        request: request,
                        statusColor: statusColor,
                      );

                      if (!isPending) return card;

                      return Dismissible(
                        key: Key(request['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete request?'),
                              content: const Text('Are you sure you want to delete this pending holiday request?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) => deleteHolidayRequest(request['id']),
                        child: card,
                      );
                    },
                  ),
                ),
    );
  }
}

class _HolidayRequestCard extends StatelessWidget {
  final dynamic request;
  final Color Function(String) statusColor;

  const _HolidayRequestCard({
    required this.request,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${request['start_date']} → ${request['end_date']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor(request['status']).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (request['status'] ?? '').toUpperCase(),
                  style: TextStyle(
                    color: statusColor(request['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _InfoRow('Department', request['department']?['name'] ?? 'N/A'),
          _InfoRow('Total Days', '${request['total_days'] ?? 0}'),
          _InfoRow('Reason', request['reason'] ?? 'No reason provided'),
          if (request['approver'] != null)
            _InfoRow('Approved By', request['approver']['name'] ?? 'N/A'),
          if (request['manager_note'] != null)
            _InfoRow('Manager Note', request['manager_note']),
          const SizedBox(height: 8),
          Text(
            'Submitted: ${(request['created_at'] ?? '').toString().substring(0, 10)}',
            style: TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          if (request['status'] == 'pending') ...[
            const SizedBox(height: 8),
            const Text(
              'Swipe left to delete',
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}


/* ================= CHANGE PASSWORD SCREEN ================= */

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  Future<void> changePassword() async {
    if (newPasswordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm password do not match')),
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'current_password': currentPasswordController.text.trim(),
        'new_password': newPasswordController.text.trim(),
        'new_password_confirmation': confirmPasswordController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Something went wrong')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your current password and choose a new one',
                style: TextStyle(color: AppColors.grey),
              ),
              const SizedBox(height: 24),

              // Current Password
              TextField(
                controller: currentPasswordController,
                obscureText: hideCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hideCurrent = !hideCurrent),
                    icon: Icon(hideCurrent ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // New Password
              TextField(
                controller: newPasswordController,
                obscureText: hideNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hideNew = !hideNew),
                    icon: Icon(hideNew ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: hideConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hideConfirm = !hideConfirm),
                    icon: Icon(hideConfirm ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : changePassword,
                  icon: isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Icon(Icons.lock_reset),
                  label: const Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= MY PROFILE SCREEN ================= */

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool isLoading = true;
  bool isSaving = false;
  Uint8List? selectedImageBytes;
  XFile? selectedImage;
  final ImagePicker picker = ImagePicker();

  Map<String, dynamic>? user;
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> pickProfileImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    }
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        user = data['user'];
        phoneController.text = data['user']['phone'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateProfile() async {
    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/update'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['phone'] = phoneController.text.trim();

    if (selectedImage != null) {
      final imageBytes = await selectedImage!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: selectedImage!.name,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    setState(() => isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Profile updated')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() => selectedImage = null);
      fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user?['name'] ?? '';
    final email = user?['email'] ?? '';
    final role = user?['role']?['name'] ?? 'N/A';
    final department = user?['department']?['name'] ?? 'N/A';
    final imageUrl = user?['image_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickProfileImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: selectedImageBytes != null
                                      ? Image.memory(
                                          selectedImageBytes!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : Center(
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _ProfileRow('Role', role.toUpperCase()),
                        _ProfileRow('Department', department.toUpperCase()),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : updateProfile,
                            icon: isSaving
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : const Icon(Icons.save),
                            label: const Text('Update Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: TextStyle(color: AppColors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/* ================= MY ROTA SCREEN ================= */

class MyRotaScreen extends StatefulWidget {
  const MyRotaScreen({super.key});

  @override
  State<MyRotaScreen> createState() => _MyRotaScreenState();
}

class _MyRotaScreenState extends State<MyRotaScreen> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  bool isLoading = true;
  List shifts = [];
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchRota();
  }

  Future<void> fetchRota() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-rota'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          shifts = data['shifts'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List getShiftsForDay(DateTime day) {
    return shifts.where((shift) {
      final shiftDate = DateTime.parse(shift['shift_date']);
      return shiftDate.year == day.year &&
          shiftDate.month == day.month &&
          shiftDate.day == day.day;
    }).toList();
  }

  Color shiftColor(String type) {
    switch (type) {
      case 'morning':
        return Colors.blue;
      case 'evening':
        return Colors.orange;
      case 'night':
        return Colors.purple;
      case 'split':
        return Colors.pink;
      case 'holiday':
        return AppColors.success;
      case 'sick':
        return AppColors.danger;
      case 'day_off':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedShifts = getShiftsForDay(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rota'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: focusedDay,
                    calendarFormat: calendarFormat,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    rowHeight: MediaQuery.of(context).size.width < 400 ? 44 : 54,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    eventLoader: (day) => getShiftsForDay(day),
                  ),
                ),
                Expanded(
                  child: selectedShifts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No shifts for selected date',
                                style: TextStyle(color: AppColors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: selectedShifts.length,
                          itemBuilder: (context, index) {
                            final shift = selectedShifts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: shiftColor(shift['shift_type']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.schedule,
                                      color: shiftColor(shift['shift_type']),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (shift['shift_type'] ?? '').replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: shiftColor(shift['shift_type']),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          shift['start_time'] != null
                                              ? '${shift['start_time']} - ${shift['end_time']}'
                                              : 'No shift time',
                                          style: TextStyle(color: AppColors.grey),
                                        ),
                                        if (shift['notes'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            shift['notes'],
                                            style: TextStyle(color: AppColors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/* ================= KITCHEN INVENTORY SCREEN ================= */

class KitchenInventoryScreen extends StatefulWidget {
  const KitchenInventoryScreen({super.key});

  @override
  State<KitchenInventoryScreen> createState() => _KitchenInventoryScreenState();
}

class _KitchenInventoryScreenState extends State<KitchenInventoryScreen> {
  bool isLoading = true;
  List items = [];

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kitchen/inventory'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          items = data['items'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color stockColor(dynamic item) {
    final quantity = double.tryParse(item['quantity'].toString()) ?? 0;
    final minimum = double.tryParse(item['minimum_stock'].toString()) ?? 0;
    return quantity <= minimum ? AppColors.danger : AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Inventory'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchInventory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Menu Options
                  GridView.count(
                    crossAxisCount: isWide ?4 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 2.5 : 3.5,
                    children: [
                      _MenuCard(
                        icon: Icons.add_box_outlined,
                        title: 'Stock In',
                        subtitle: 'Add received stock',
                        color: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenStockInScreen()),
                        ).then((_) => fetchInventory()),
                      ),
                      _MenuCard(
                        icon: Icons.restaurant_menu,
                        title: 'Sales',
                        subtitle: 'Deduct recipe stock',
                        color: AppColors.warning,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenSalesScreen()),
                        ).then((_) => fetchInventory()),
                      ),
                      _MenuCard(
                        icon: Icons.food_bank_outlined,
                        title: 'Buffet Sales',
                        subtitle: 'Deduct buffet stock',
                        color: AppColors.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenBuffetSalesScreen()),
                        ).then((_) => fetchInventory()),
                      ),

                      _MenuCard(
                        icon: Icons.delete,
                        title: 'Wastage',
                        subtitle: 'Record wasted stock',
                        color: AppColors.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenWastageScreen()),
                        ).then((_) => fetchInventory()),
                      ),
                      
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Current Stock
                  const Text(
                    'Current Stock',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No inventory items found',
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ),
                    )
                                    else
                    ...items.map((item) => _InventoryCard(
                      item: item,
                      stockColor: stockColor(item),
                    )).toList(),
                ],
              ),
            ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final dynamic item;
  final Color stockColor;

  const _InventoryCard({required this.item, required this.stockColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2, color: stockColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Item',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item['category'] ?? 'Uncategorised',
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum: ${item['minimum_stock']} ${item['unit']}',
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['quantity']}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: stockColor,
                ),
              ),
              Text(
                item['unit'] ?? '',
                style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ================= KITCHEN STOCK IN SCREEN ================= */

class KitchenStockInScreen extends StatefulWidget {
  const KitchenStockInScreen({super.key});

  @override
  State<KitchenStockInScreen> createState() => _KitchenStockInScreenState();
}

class _KitchenStockInScreenState extends State<KitchenStockInScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List items = [];
  String? selectedItemId;
  final quantityController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/kitchen/inventory'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        items = data['items'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitStockIn() async {
    if (selectedItemId == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select item and enter quantity')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/inventory/stock-in'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'inventory_item_id': selectedItemId!,
        'quantity': quantityController.text.trim(),
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Stock updated')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      quantityController.clear();
      noteController.clear();
      selectedItemId = null;
      fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock In'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _FormScreen(
              children: [
                const Text(
                  'Add Stock',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Record received kitchen stock', style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),

                // Select Item
                DropdownButtonFormField<String>(
                  value: selectedItemId,
                  decoration: const InputDecoration(
                    labelText: 'Select Item',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: items.map<DropdownMenuItem<String>>((item) {
                    return DropdownMenuItem<String>(
                      value: item['id'].toString(),
                      child: Text('${item['name']} (${item['unit']})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedItemId = value),
                ),
                const SizedBox(height: 14),

                // Quantity
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 14),

                // Note
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    prefixIcon: const Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : submitStockIn,
                    icon: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.save),
                    label: const Text('Save Stock In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ================= KITCHEN SALES SCREEN ================= */

class KitchenSalesScreen extends StatefulWidget {
  const KitchenSalesScreen({super.key});

  @override
  State<KitchenSalesScreen> createState() => _KitchenSalesScreenState();
}

class _KitchenSalesScreenState extends State<KitchenSalesScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List recipes = [];
  String? selectedRecipeId;
  final quantityController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kitchen/recipes'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          recipes = data['recipes'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitSale() async {
    if (selectedRecipeId == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select recipe and enter quantity')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/recipes/$selectedRecipeId/sale'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'quantity': quantityController.text.trim(),
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Sale recorded')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      quantityController.clear();
      noteController.clear();
      selectedRecipeId = null;
      fetchRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Sales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _FormScreen(
              children: [
                const Text(
                  'Record Recipe Sale',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Select recipe and enter quantity sold', style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),

                // Select Recipe
                DropdownButtonFormField<String>(
                  value: selectedRecipeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Recipe',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  items: recipes.map<DropdownMenuItem<String>>((recipe) {
                    return DropdownMenuItem<String>(
                      value: recipe['id'].toString(),
                      child: Text(recipe['name'] ?? 'Recipe'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedRecipeId = value),
                ),
                const SizedBox(height: 14),

                // Quantity
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity Sold',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 14),

                // Note
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    prefixIcon: const Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : submitSale,
                    icon: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.save),
                    label: const Text('Save Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ================= KITCHEN BUFFET SALES SCREEN ================= */

class KitchenBuffetSalesScreen extends StatefulWidget {
  const KitchenBuffetSalesScreen({super.key});

  @override
  State<KitchenBuffetSalesScreen> createState() =>
      _KitchenBuffetSalesScreenState();
}

class _KitchenBuffetSalesScreenState extends State<KitchenBuffetSalesScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List buffets = [];
  String? selectedBuffetId;
  final paxController = TextEditingController();
  final noteController = TextEditingController();
  DateTime saleDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchBuffets();
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchBuffets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kitchen/buffets'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          buffets = data['buffets'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickSaleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: saleDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => saleDate = picked);
  }

  Future<void> submitBuffetSale() async {
    if (selectedBuffetId == null || paxController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select buffet and enter pax')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/buffets/$selectedBuffetId/sale'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'sale_date': formatDate(saleDate),
        'pax': paxController.text.trim(),
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Buffet sale recorded')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      paxController.clear();
      noteController.clear();
      selectedBuffetId = null;
      saleDate = DateTime.now();
      fetchBuffets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buffet Sales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _FormScreen(
              children: [
                const Text(
                  'Record Buffet Sale',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Enter buffet pax sold to deduct inventory', style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),

                // Select Buffet
                DropdownButtonFormField<String>(
                  value: selectedBuffetId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Buffet',
                    prefixIcon: Icon(Icons.food_bank_outlined),
                  ),
                  items: buffets.map<DropdownMenuItem<String>>((buffet) {
                    return DropdownMenuItem<String>(
                      value: buffet['id'].toString(),
                      child: Text(buffet['name'] ?? 'Buffet'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedBuffetId = value),
                ),
                const SizedBox(height: 14),

                // Sale Date
                InkWell(
                  onTap: pickSaleDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                                        width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sale Date', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(formatDate(saleDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Pax Sold
                TextField(
                  controller: paxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pax Sold',
                    prefixIcon: Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 14),

                // Note
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    prefixIcon: const Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : submitBuffetSale,
                    icon: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.save),
                    label: const Text('Save Buffet Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ================= SHARED FORM SCREEN WIDGET ================= */

class _FormScreen extends StatelessWidget {
  final List<Widget> children;

  const _FormScreen({required this.children});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

//wastage record screen
class KitchenWastageScreen extends StatefulWidget {
  const KitchenWastageScreen({super.key});

  @override
  State<KitchenWastageScreen> createState() => _KitchenWastageScreenState();
}

class _KitchenWastageScreenState extends State<KitchenWastageScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List items = [];
  String? selectedItemId;
  String? reason;

  final quantityController = TextEditingController();
  final noteController = TextEditingController();

  final reasons = const [
    'expired',
    'spoiled',
    'damaged',
    'burnt',
    'overproduction',
    'staff_meal',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/kitchen/inventory'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        items = data['items'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitWastage() async {
    if (selectedItemId == null || quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select item and enter quantity')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/wastage'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'inventory_item_id': selectedItemId!,
        'quantity': quantityController.text.trim(),
        'reason': reason ?? '',
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);

    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Wastage recorded')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      selectedItemId = null;
      reason = null;
      quantityController.clear();
      noteController.clear();
      fetchItems();
      setState(() {});
    }
  }

  String cleanText(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Kitchen Wastage'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 560 : double.infinity,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Wastage',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Record expired, damaged, spoiled, or wasted stock.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 22),

                      DropdownButtonFormField<String>(
                        value: selectedItemId,
                        isExpanded: true,
                        decoration: inputDecoration(
                          'Select Inventory Item',
                          Icons.inventory_2,
                        ),
                        items: items.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(
                              '${item['name']} (${item['quantity']} ${item['unit']})',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedItemId = value);
                        },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration(
                          'Quantity Wasted',
                          Icons.numbers,
                        ),
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: reason,
                        isExpanded: true,
                        decoration: inputDecoration(
                          'Reason',
                          Icons.warning,
                        ),
                        items: reasons.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(cleanText(item)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => reason = value);
                        },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: inputDecoration(
                          'Note optional',
                          Icons.note,
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submitWastage,
                          icon: const Icon(Icons.delete),
                          label: isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Record Wastage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

InputDecoration inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}