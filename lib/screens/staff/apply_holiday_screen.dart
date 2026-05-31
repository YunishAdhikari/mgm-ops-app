import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';

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
