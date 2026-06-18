import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

class HkInspectionScreen extends StatefulWidget {
  const HkInspectionScreen({super.key});

  @override
  State<HkInspectionScreen> createState() => _HkInspectionScreenState();
}

class _HkInspectionScreenState extends State<HkInspectionScreen> {
  bool isLoading = true;
  bool isUpdating = false;

  String token = '';
  List rooms = [];

  @override
  void initState() {
    super.initState();
    loadRooms();
  }

  Future<void> loadRooms() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hk/supervisor/inspection'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          rooms = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        showMessage(data['message'] ?? 'Failed to load inspection rooms');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Network error. Please try again.');
    }
  }

  Future<void> approveRoom(int id) async {
    if (isUpdating) return;

    setState(() => isUpdating = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hk/supervisor/inspection/$id/approve'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        showMessage(data['message'] ?? 'Room approved successfully');
        await loadRooms();
      } else {
        showMessage(data['message'] ?? 'Failed to approve room');
      }
    } catch (e) {
      showMessage('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  Future<void> rejectRoom(int id, String reason) async {
    if (isUpdating) return;

    setState(() => isUpdating = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hk/supervisor/inspection/$id/reject'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        showMessage(data['message'] ?? 'Room rejected successfully');
        await loadRooms();
      } else {
        showMessage(data['message'] ?? 'Failed to reject room');
      }
    } catch (e) {
      showMessage('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  void showRejectDialog(int id) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Reject Room'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Reason for rejection...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () {
                      final reason = controller.text.trim();

                      if (reason.isEmpty) {
                        showMessage('Please enter a reason.');
                        return;
                      }

                      Navigator.pop(context);
                      rejectRoom(id, reason);
                    },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String pretty(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll('_', ' ')
        .split(' ')
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f8),
      appBar: AppBar(
        title: const Text('Inspection Queue'),
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : rooms.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadRooms,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 220),
                          Center(
                            child: Text('No rooms waiting for inspection.'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadRooms,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rooms.length,
                        itemBuilder: (_, index) {
                          final room = rooms[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xff14b8a6)
                                          .withOpacity(0.1),
                                      child: Text(
                                        room['room_number']?.toString() ?? '-',
                                        style: const TextStyle(
                                          color: Color(0xff0f766e),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pretty(room['room_status']),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            room['staff_name']?.toString() ??
                                                'Unknown Staff',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if ((room['notes'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff9fafb),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(room['notes'].toString()),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.check),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: isUpdating
                                            ? null
                                            : () => approveRoom(room['id']),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: isUpdating
                                            ? null
                                            : () =>
                                                showRejectDialog(room['id']),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          if (isUpdating)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}