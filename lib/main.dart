import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// const String baseUrl = 'http://172.31.0.41:8000/api';
const String baseUrl = 'http://172.20.10.3:8000/api';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    debugPrint('FCM TOKEN: $token');
  }

  runApp(const MgmOpsApp());
}

class MgmOpsApp extends StatelessWidget {
  const MgmOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MGM Ops',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
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
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
        },
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
        await prefs.setString(
          'department',
          data['user']['department']?['name'] ?? '',
        );

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
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 480 : double.infinity,
                  ),
                  padding: EdgeInsets.all(isWide ? 36 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'MGM Ops',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffff15c4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Staff Login',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1583ff),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Login',
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
            );
          },
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
    final isMaintenance = department == 'Maintenance';

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('MGM Ops'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
            int crossAxisCount;

              if (constraints.maxWidth >= 1000) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth >= 700) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth >= 420) {
                crossAxisCount = 2;
              } else {
                crossAxisCount = 1;
              }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff1583ff),
                          Color(0xffff15c4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          department.isEmpty ? 'No Department' : department,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    // childAspectRatio: 1.15,
                    childAspectRatio: constraints.maxWidth < 420 ? 2.8 : 1.15,
                    children: [
                      // dashboardItem(Icons.people, 'Staff Directory'),

                      dashboardItem(
                            Icons.people,
                            'Staff Directory',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StaffDirectoryScreen(),
                                ),
                              );
                            },
                          ),

                            dashboardItem(
                              Icons.schedule,
                              'My Rota',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyRotaScreen(),
                                  ),
                                );
                              },
                            ),
                      // dashboardItem(
                      //     Icons.calendar_month,
                      //     'Holiday Request',
                      //     onTap: () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (_) => const ApplyHolidayScreen (),
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // dashboardItem(Icons.newspaper, 'News & Blogs'),
                      dashboardItem(
                            Icons.newspaper,
                            'News & Blogs',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NewsScreen(),
                                ),
                              );
                            },
                          ),
                      // dashboardItem(Icons.build, 'Add Maintenance'),

                        dashboardItem(
                          Icons.build,
                          'Add Maintenance',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddMaintenanceScreen()),
                            );
                          },
                        ),

                      dashboardItem(
                        Icons.list_alt,
                        'Maintenance Jobs',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MaintenanceJobsScreen(),
                            ),
                          );
                        },
                      ),
                      if (isMaintenance)
                        dashboardItem(Icons.task_alt, 'My Tasks'),
                      if (isMaintenance)
                        dashboardItem(Icons.edit_note, 'Update Notes'),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget dashboardItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: const Color(0xff1583ff)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= MAINTENANCE JOBS SCREEN ================= */

class MaintenanceJobsScreen extends StatefulWidget {
  const MaintenanceJobsScreen({super.key});

  @override
  State<MaintenanceJobsScreen> createState() => _MaintenanceJobsScreenState();
}

class _MaintenanceJobsScreenState extends State<MaintenanceJobsScreen> {
  bool isLoading = true;
  List jobs = [];

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

      // if (response.statusCode == 200 && data['success'] == true) {
      //   setState(() {
      //     // jobs = data['jobs'];
      //     jobs = List<Map<String, dynamic>>.from(data['jobs']);
      //     isLoading = false;
      //   });
      // } 
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          jobs = List<Map<String, dynamic>>.from(data['jobs']);
          isLoading = false;
        });
      }
      else {
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

  String cleanText(String text) {
    return text.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Maintenance Jobs'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
              ? const Center(child: Text('No maintenance jobs found.'))
              : RefreshIndicator(
                  onRefresh: fetchJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];


                      return InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaintenanceJobDetailScreen(job: job),
                              ),
                            ).then((_) => fetchJobs());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (job['image_url'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      job['image_url'],
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 180,
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                if (job['image_url'] != null)
                                  const SizedBox(height: 14),

                                Text(
                                  job['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  job['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    badge(
                                      cleanText(job['priority'] ?? ''),
                                      priorityColor(job['priority'] ?? ''),
                                    ),
                                    const SizedBox(width: 10),
                                    badge(
                                      cleanText(job['status'] ?? ''),
                                      statusColor(job['status'] ?? ''),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${job['location'] ?? 'N/A'} | Room: ${job['room_number'] ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                      // return InkWell(
                      //         borderRadius: BorderRadius.circular(22),
                      //         onTap: () {
                      //           Navigator.push(
                      //             context,
                      //             MaterialPageRoute(
                      //               builder: (_) => MaintenanceJobDetailScreen(job: job),
                      //             ),
                      //           ).then((_) => fetchJobs());
                      //         },
                      //         child: Container());
                    },
                  ),
                ),
    );
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

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
      body: {
        'status': status,
      },
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
      body: {
        'note': noteController.text,
      },
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
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.job['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  widget.job['image_url'],
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 18),

            detailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.job['description'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 18),

                  infoRow('Priority', widget.job['priority'] ?? 'N/A'),
                  infoRow('Status', widget.job['status'] ?? 'N/A'),
                  infoRow('Location', widget.job['location'] ?? 'N/A'),
                  infoRow('Room', widget.job['room_number'] ?? 'N/A'),
                  infoRow(
                    'Reported By',
                    widget.job['reporter']?['name'] ?? 'N/A',
                  ),
                  infoRow(
                    'Assigned To',
                    widget.job['assigned_user']?['name'] ?? 'Not Assigned',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            detailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maintenance Note',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    enabled: isMaintenance,
                    decoration: InputDecoration(
                      hintText: 'Add maintenance note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  if (isMaintenance) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isUpdating ? null : updateNote,
                        icon: const Icon(Icons.save),
                        label: const Text('Update Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1583ff),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isMaintenance) ...[
              const SizedBox(height: 18),

              detailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => status = value);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isUpdating ? null : updateStatus,
                        icon: const Icon(Icons.update),
                        label: const Text('Update Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffff15c4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget detailCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

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
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(22),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                  );

                  if (image != null) {
                    setState(() {
                      selectedImage = image;
                    });
                  }
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
                  );

                  if (image != null) {
                    setState(() {
                      selectedImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
//   Future<void> pickImage() async {
//   final image = await picker.pickImage(
//     source: ImageSource.gallery,
//     imageQuality: 75,
//   );

//   if (image != null) {
//     setState(() {
//       selectedImage = image;
//     });
//   }
// }

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

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: selectedImage!.name,
      ),
    );
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  final data = jsonDecode(response.body);

  setState(() => isLoading = false);

  if (!mounted) return;

  if (response.statusCode == 201 && data['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Task added')),
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
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Add Maintenance Task'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: isDepartmentLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    inputField(
                      controller: titleController,
                      label: 'Task Title',
                      icon: Icons.title,
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: selectedDepartment,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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

                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: const Icon(Icons.priority_high),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => priority = value);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    inputField(
                      controller: locationController,
                      label: 'Location',
                      icon: Icons.location_on,
                    ),

                    const SizedBox(height: 14),

                    inputField(
                      controller: roomController,
                      label: 'Room Number',
                      icon: Icons.meeting_room,
                    ),

                    const SizedBox(height: 24),
                    const SizedBox(height: 14),

                      InkWell(
                        onTap: pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.image,
                                size: 38,
                                color: Color(0xff1583ff),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedImage == null
                                    ? 'Tap to upload image'
                                    : selectedImage!.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : submitTask,
                        icon: const Icon(Icons.add),
                        label: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit Maintenance Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1583ff),
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
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}


//news
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

      if (response.statusCode == 200 &&
          data['success'] == true) {

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
      backgroundColor: const Color(0xfff4f7fb),

      appBar: AppBar(
        title: const Text('News & Blogs'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )

          : news.isEmpty
              ? const Center(
                  child: Text('No news available'),
                )

              : RefreshIndicator(
                  onRefresh: fetchNews,

                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: news.length,

                    itemBuilder: (context, index) {

                      final item = news[index];

                      return InkWell(

                        borderRadius: BorderRadius.circular(22),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NewsDetailScreen(news: item),
                            ),
                          );
                        },

                        child: Container(
                          margin: const EdgeInsets.only(bottom: 18),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              if (item['image_url'] != null)

                                ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(
                                    top: Radius.circular(22),
                                  ),

                                  child: Image.network(
                                    item['image_url'],
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                              Padding(
                                padding: const EdgeInsets.all(18),

                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [

                                    Text(
                                      item['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      item['description'] ?? '',
                                      maxLines: 3,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        height: 1.6,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    Row(
                                      children: [

                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey,
                                        ),

                                        const SizedBox(width: 6),

                                        Text(
                                          item['created_at']
                                              .toString()
                                              .substring(0, 10),

                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


//news details

class NewsDetailScreen extends StatelessWidget {

  final Map news;

  const NewsDetailScreen({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      appBar: AppBar(
        title: const Text('News Details'),
        backgroundColor: const Color(0xff1583ff),
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
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [

                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        news['created_at']
                            .toString()
                            .substring(0, 10),

                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    news['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.black87,
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

class StaffDirectoryScreen extends StatelessWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Staff Directory'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff1583ff),
                    Color(0xffff15c4),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your staff options and requests.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            staffOption(
              context,
              icon: Icons.calendar_month,
              title: 'Apply Holiday',
              subtitle: 'Submit a new holiday request',
              color: const Color(0xff1583ff),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ApplyHolidayScreen(),
                  ),
                );
              },
            ),

            staffOption(
              context,
              icon: Icons.history,
              title: 'Past Holidays',
              subtitle: 'View your holiday request history',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyHolidayRequestsScreen(),
                  ),
                );
              },
            ),

            staffOption(
              context,
              icon: Icons.lock_reset,
              title: 'Change Password',
              subtitle: 'Update your account password',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),

            staffOption(
              context,
              icon: Icons.people_alt,
              title: 'My Profile',
              subtitle: 'View and update your profile',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget staffOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

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
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Apply Holiday'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Holiday Request',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose your holiday dates and submit your request to management.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              dateBox(
                title: 'Start Date',
                value: formatDate(startDate),
                onTap: () => pickDate(isStart: true),
              ),

              const SizedBox(height: 14),

              dateBox(
                title: 'End Date',
                value: formatDate(endDate),
                onTap: () => pickDate(isStart: false),
              ),

              const SizedBox(height: 14),

              if (totalDays > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff1583ff).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Total Days: $totalDays',
                    style: const TextStyle(
                      color: Color(0xff1583ff),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Optional reason for your holiday request',
                  prefixIcon: const Icon(Icons.note_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : submitHoliday,
                  icon: const Icon(Icons.send),
                  label: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Holiday Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1583ff),
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
    );
  }

  Widget dateBox({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xff1583ff)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
//past holiday screen
class MyHolidayRequestsScreen extends StatefulWidget {
  const MyHolidayRequestsScreen({super.key});

  @override
  State<MyHolidayRequestsScreen> createState() =>
      _MyHolidayRequestsScreenState();
}

class _MyHolidayRequestsScreenState
    extends State<MyHolidayRequestsScreen> {

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

      if (response.statusCode == 200 &&
          data['success'] == true) {

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

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  String cleanText(String text) {
    return text.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      appBar: AppBar(
        title: const Text('My Holiday Requests'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )

          : requests.isEmpty
              ? const Center(
                  child: Text(
                    'No holiday requests found.',
                  ),
                )

              : RefreshIndicator(
                  onRefresh: fetchRequests,

                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),

                    itemCount: requests.length,

                    itemBuilder: (context, index) {

                      final request = requests[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(18),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [

                                  Expanded(
                                    child: Text(
                                      '${request['start_date']} → ${request['end_date']}',

                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),

                                    decoration: BoxDecoration(
                                      color: statusColor(
                                        request['status'],
                                      ).withOpacity(0.12),

                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),

                                    child: Text(
                                      cleanText(
                                        request['status'],
                                      ),

                                      style: TextStyle(
                                        color: statusColor(
                                          request['status'],
                                        ),

                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              infoRow(
                                'Department',
                                request['department']?['name'] ?? 'N/A',
                              ),

                              infoRow(
                                'Total Days',
                                '${request['total_days'] ?? 0}',
                              ),

                              infoRow(
                                'Reason',
                                request['reason'] ?? 'No reason provided',
                              ),

                              if (request['approver'] != null)
                                infoRow(
                                  'Approved By',
                                  request['approver']['name'] ?? 'N/A',
                                ),

                              if (request['manager_note'] != null)
                                infoRow(
                                  'Manager Note',
                                  request['manager_note'],
                                ),

                              const SizedBox(height: 8),

                              Text(
                                'Submitted: ${request['created_at'].toString().substring(0, 10)}',

                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(
            width: 110,

            child: Text(
              title,

              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
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
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Password',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Please enter your current password and choose a new one.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              passwordField(
                controller: currentPasswordController,
                label: 'Current Password',
                hidden: hideCurrent,
                onToggle: () {
                  setState(() => hideCurrent = !hideCurrent);
                },
              ),

              const SizedBox(height: 14),

              passwordField(
                controller: newPasswordController,
                label: 'New Password',
                hidden: hideNew,
                onToggle: () {
                  setState(() => hideNew = !hideNew);
                },
              ),

              const SizedBox(height: 14),

              passwordField(
                controller: confirmPasswordController,
                label: 'Confirm New Password',
                hidden: hideConfirm,
                onToggle: () {
                  setState(() => hideConfirm = !hideConfirm);
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : changePassword,
                  icon: const Icon(Icons.lock_reset),
                  label: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1583ff),
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
    );
  }

  Widget passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            hidden ? Icons.visibility : Icons.visibility_off,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}


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

Future<void> pickProfileImage() async {
  final image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 75,
  );

  if (image != null) {
    final bytes = await image.readAsBytes();

    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
    });
  }
}

  Map<String, dynamic>? user;
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
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

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: selectedImage!.name,
      ),
    );
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
    setState(() {
      selectedImage = null;
    });

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
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff1583ff),
                          Color(0xffff15c4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
  onTap: pickProfileImage,
  child: Stack(
    children: [
      CircleAvatar(
        radius: 45,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: selectedImageBytes != null
              ? Image.memory(
                  selectedImageBytes!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                )
              : imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1583ff),
                        ),
                      ),
                    ),
        ),
      ),

      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: Color(0xff1583ff),
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
                        const SizedBox(height: 14),

                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  profileCard(
                    children: [
                      profileRow('Role', role),
                      profileRow('Department', department),

                      const SizedBox(height: 16),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : updateProfile,
                          icon: const Icon(Icons.save),
                          label: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Update Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1583ff),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget profileCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget profileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString().toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;

  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '$title page coming soon',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

//Rota
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
        return Colors.green;
      case 'sick':
        return Colors.red;
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
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('My Rota'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(18),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  //table calander
                  child: TableCalendar(
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2035, 12, 31),
                        focusedDay: focusedDay,

                        calendarFormat: calendarFormat,

                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },

                        rowHeight: MediaQuery.of(context).size.width < 400 ? 42 : 52,

                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),

                        selectedDayPredicate: (day) {
                          return isSameDay(selectedDay, day);
                        },

                        onDaySelected: (selected, focused) {
                          setState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },

                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xff1583ff),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),

                        eventLoader: (day) {
                          return getShiftsForDay(day);
                        },
                      ),
               
            
                ),

                Expanded(
                  child: selectedShifts.isEmpty
                      ? const Center(
                          child: Text(
                            'No shifts for selected date.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          itemCount: selectedShifts.length,
                          itemBuilder: (context, index) {
                            final shift = selectedShifts[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        shiftColor(shift['shift_type'])
                                            .withOpacity(0.15),
                                    child: Icon(
                                      Icons.schedule,
                                      color:
                                          shiftColor(shift['shift_type']),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shift['shift_type']
                                              .toString()
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: shiftColor(
                                                shift['shift_type']),
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          shift['start_time'] != null
                                              ? '${shift['start_time']} - ${shift['end_time']}'
                                              : 'No shift time',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),

                                        if (shift['notes'] != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            shift['notes'],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
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