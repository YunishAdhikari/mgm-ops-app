import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import 'maintenance_job_detail_screen.dart';
import '../../core/constants.dart';



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