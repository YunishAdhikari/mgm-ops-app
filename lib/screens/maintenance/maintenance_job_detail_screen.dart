import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';

class MaintenanceJobDetailScreen extends StatefulWidget {
  final Map job;

  const MaintenanceJobDetailScreen({
    super.key,
    required this.job,
  });

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

    status = widget.job['status']?.toString() ?? 'pending';

    noteController = TextEditingController(
      text: widget.job['note']?.toString() ??
          widget.job['maintenance_note']?.toString() ??
          widget.job['internal_note']?.toString() ??
          '',
    );

    loadUserDepartment();
  }

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

  Future<void> loadUserDepartment() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      department = prefs.getString('department') ?? '';
    });
  }

  bool get isMaintenance {
    final dept = department.toLowerCase();

    return dept == 'maintenance' ||
        dept.contains('maintenance') ||
        dept == 'admin' ||
        dept == 'manager';
  }

  Future<void> updateStatus() async {
    setState(() => isUpdating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
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

      Map<String, dynamic> data = {};

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {
          'message': 'Invalid server response.',
        };
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Status updated.'),
          backgroundColor:
              response.statusCode >= 200 && response.statusCode < 300
                  ? Colors.green
                  : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => isUpdating = false);
    }
  }

  Future<void> updateNote() async {
    setState(() => isUpdating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/maintenance/jobs/${widget.job['id']}/note'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'note': noteController.text.trim(),
        },
      );

      Map<String, dynamic> data = {};

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {
          'message': 'Invalid server response.',
        };
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Note updated.'),
          backgroundColor:
              response.statusCode >= 200 && response.statusCode < 300
                  ? Colors.green
                  : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => isUpdating = false);
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = getMaintenanceImageUrl(widget.job);

    return Scaffold(
      backgroundColor: const Color(0xfff7f7fb),
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
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  headers: const {
                    'Accept': 'image/*',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    return Container(
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('IMAGE ERROR: $error');
                    debugPrint('IMAGE URL: $imageUrl');

                    return const _ImageFallback();
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const _ImageFallback(),
              const SizedBox(height: 16),
            ],

            _DetailCard(
              children: [
                Text(
                  widget.job['title']?.toString() ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  widget.job['description']?.toString() ?? '',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const Divider(height: 24),

                _InfoRow(
                  'Priority',
                  (widget.job['priority']?.toString() ?? 'N/A').toUpperCase(),
                ),

                _InfoRow(
                  'Status',
                  (widget.job['status']?.toString() ?? 'N/A')
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                ),

                _InfoRow(
                  'Location',
                  widget.job['location']?.toString() ?? 'N/A',
                ),

                _InfoRow(
                  'Room',
                  widget.job['room_number']?.toString() ?? 'N/A',
                ),

                _InfoRow(
                  'Reported By',
                  widget.job['reporter']?['name']?.toString() ??
                      widget.job['reported_by_user']?['name']?.toString() ??
                      widget.job['reported_by']?['name']?.toString() ??
                      'N/A',
                ),

                _InfoRow(
                  'Assigned To',
                  widget.job['assigned_user']?['name']?.toString() ??
                      widget.job['assigned_to_user']?['name']?.toString() ??
                      widget.job['assigned_to']?['name']?.toString() ??
                      'Not Assigned',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _DetailCard(
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
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),

                if (!isMaintenance) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Only maintenance team can update this note.',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],

                if (isMaintenance) ...[
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isUpdating ? null : updateNote,
                      icon: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        isUpdating ? 'Updating...' : 'Update Note',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
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

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isUpdating ? null : updateStatus,
                      icon: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.update),
                      label: Text(
                        isUpdating ? 'Updating...' : 'Update Status',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 46,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
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

  const _InfoRow(
    this.title,
    this.value,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
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