import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import 'maintenance_job_detail_screen.dart';

class MaintenanceHomeScreen extends StatelessWidget {
  const MaintenanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xfff7f7fb),
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

/* ================= HELPERS ================= */

String? getMaintenanceImageUrl(Map job) {
  final appUrl = baseUrl.replaceAll('/api', '');

  final possibleImage = job['image_url'] ??
      job['image'] ??
      job['image_path'] ??
      job['photo'] ??
      job['photo_url'];

  if (possibleImage == null) return null;

  var image = possibleImage.toString().trim();

  if (image.isEmpty || image == 'null') return null;

  if (image.startsWith('http://') || image.startsWith('https://')) {
    return image;
  }

  image = image.replaceAll('\\', '/');

  if (image.startsWith('/')) {
    image = image.substring(1);
  }

  if (image.startsWith('public/')) {
    image = image.replaceFirst('public/', 'storage/');
  }

  if (!image.startsWith('storage/') && !image.startsWith('uploads/')) {
    image = 'storage/$image';
  }

  return '$appUrl/$image';
}

Color priorityColor(String priority) {
  switch (priority.toLowerCase()) {
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
  switch (status.toLowerCase()) {
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

/* ================= ACTIVE MAINTENANCE TAB ================= */

class ActiveMaintenanceTab extends StatefulWidget {
  const ActiveMaintenanceTab({super.key});

  @override
  State<ActiveMaintenanceTab> createState() => _ActiveMaintenanceTabState();
}

class _ActiveMaintenanceTabState extends State<ActiveMaintenanceTab> {
  bool isLoading = true;
  List<Map<String, dynamic>> activeJobs = [];

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
      debugPrint('Maintenance fetch error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeJobs.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Active Jobs',
        subtitle: 'All maintenance jobs are up to date',
      );
    }

    return RefreshIndicator(
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
          );
        },
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
  List<Map<String, dynamic>> pastJobs = [];

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
      debugPrint('Maintenance fetch error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pastJobs.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: 'No Past Jobs',
        subtitle: 'Completed and cancelled jobs will appear here',
      );
    }

    return RefreshIndicator(
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
          );
        },
      ),
    );
  }
}

/* ================= EMPTY STATE ================= */

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

/* ================= JOB CARD ================= */

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = getMaintenanceImageUrl(job);

    final priority = job['priority']?.toString() ?? 'low';
    final status = job['status']?.toString() ?? 'pending';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 170,
                      fit: BoxFit.cover,
                      headers: const {
                        'Accept': 'image/*',
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return Container(
                          height: 170,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('IMAGE ERROR: $error');
                        debugPrint('IMAGE URL: $imageUrl');

                        return _ImageFallback();
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  _ImageFallback(),
                  const SizedBox(height: 14),
                ],

                Text(
                  job['title']?.toString() ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  job['description']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey,
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      text: priority.replaceAll('_', ' ').toUpperCase(),
                      color: priorityColor(priority),
                    ),
                    _Badge(
                      text: status.replaceAll('_', ' ').toUpperCase(),
                      color: statusColor(status),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${job['location'] ?? 'N/A'} | Room: ${job['room_number'] ?? 'N/A'}',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= IMAGE FALLBACK ================= */

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 42,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

/* ================= BADGE ================= */

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}