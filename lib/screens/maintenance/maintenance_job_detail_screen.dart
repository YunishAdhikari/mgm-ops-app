import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';


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