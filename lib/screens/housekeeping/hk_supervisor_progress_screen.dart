import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

class HkSupervisorProgressScreen extends StatefulWidget {
  const HkSupervisorProgressScreen({super.key});

  @override
  State<HkSupervisorProgressScreen> createState() =>
      _HkSupervisorProgressScreenState();
}

class _HkSupervisorProgressScreenState
    extends State<HkSupervisorProgressScreen> {
  bool isLoading = true;
  String token = '';

  Map summary = {};
  List staffList = [];

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hk/supervisor/progress'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          summary = data['data']['summary'] ?? {};
          staffList = data['data']['staff'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        showMessage(data['message'] ?? 'Failed to load progress');
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage('Connection error. Please check your server.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String normalize(dynamic value) {
    return (value ?? '')
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }

  String pretty(dynamic value) {
    final text = (value ?? '').toString();

    if (text.isEmpty || text == 'null') return 'Pending';
    if (normalize(text) == 'assigned') return 'Pending';

    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Color statusColor(String status) {
    final value = normalize(status);

    if (value == 'assigned' || value == 'pending' || value.isEmpty) {
      return const Color(0xfff59e0b);
    }

    switch (value) {
      case 'in_progress':
        return const Color(0xff2563eb);
      case 'cleaned':
        return const Color(0xff16a34a);
      case 'dnd':
        return const Color(0xff7c3aed);
      case 'refused_service':
        return const Color(0xffdc2626);
      case 'inspected':
        return const Color(0xff0f766e);
      default:
        return const Color(0xff6b7280);
    }
  }

  int summaryValue(String key) {
    return int.tryParse((summary[key] ?? 0).toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final total = summaryValue('total');
    final cleaned = summaryValue('cleaned');
    final progress = total == 0 ? 0.0 : cleaned / total;

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      appBar: AppBar(
        title: const Text('HK Progress'),
        backgroundColor: const Color(0xff111827),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadProgress,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProgress,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(total, cleaned, progress),
                  const SizedBox(height: 18),
                  const Text(
                    'Staff Progress',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (staffList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'No HK allocation found for today.',
                          style: TextStyle(
                            color: Color(0xff6b7280),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ...staffList.map((staff) => _buildStaffCard(staff)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(int total, int cleaned, double progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today Housekeeping Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live room cleaning progress',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xff22c55e)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryItem('Total', total.toString()),
              _summaryItem('Pending', summaryValue('pending').toString()),
              _summaryItem('Doing', summaryValue('in_progress').toString()),
              _summaryItem('Cleaned', cleaned.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem('DND', summaryValue('dnd').toString()),
              _summaryItem('Refused', summaryValue('refused').toString()),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(dynamic staff) {
    final rooms = staff['rooms'] ?? [];
    final total = int.tryParse((staff['total'] ?? 0).toString()) ?? 0;
    final cleaned = int.tryParse((staff['cleaned'] ?? 0).toString()) ?? 0;
    final percentage = total == 0 ? 0.0 : cleaned / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          staff['staff_name']?.toString() ?? 'Unknown Staff',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Color(0xff111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$cleaned of $total rooms cleaned',
                style: const TextStyle(
                  color: Color(0xff6b7280),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 7,
                  backgroundColor: const Color(0xffe5e7eb),
                  valueColor: const AlwaysStoppedAnimation(Color(0xff22c55e)),
                ),
              ),
            ],
          ),
        ),
        trailing: CircleAvatar(
          backgroundColor: const Color(0xff14b8a6).withOpacity(0.12),
          child: Text(
            total.toString(),
            style: const TextStyle(
              color: Color(0xff0f766e),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          const SizedBox(height: 8),
          _staffMiniStats(staff),
          const SizedBox(height: 12),
          ...rooms.map((room) => _roomRow(room)),
        ],
      ),
    );
  }

  Widget _staffMiniStats(dynamic staff) {
    return Row(
      children: [
        _miniStat('Pending', staff['pending']),
        _miniStat('Doing', staff['in_progress']),
        _miniStat('Cleaned', staff['cleaned']),
        _miniStat('DND', staff['dnd']),
      ],
    );
  }

  Widget _miniStat(String label, dynamic value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xfff9fafb),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              (value ?? 0).toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xff111827),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xff6b7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomRow(dynamic room) {
    final status = room['cleaning_status']?.toString() ?? 'assigned';
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xfff9fafb),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xff14b8a6).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              room['room_number']?.toString() ?? '-',
              style: const TextStyle(
                color: Color(0xff0f766e),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pretty(room['room_status']),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xff374151),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pretty(status),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}