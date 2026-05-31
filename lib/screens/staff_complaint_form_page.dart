import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StaffComplaintFormPage extends StatefulWidget {
  final String authToken;

  const StaffComplaintFormPage({
    super.key,
    required this.authToken,
  });

  @override
  State<StaffComplaintFormPage> createState() => _StaffComplaintFormPageState();
}

class _StaffComplaintFormPageState extends State<StaffComplaintFormPage> {
  final formKey = GlobalKey<FormState>();

  final guestNameController = TextEditingController();
  final roomNumberController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = 'Maintenance';
  String priority = 'medium';

  bool isSubmitting = false;

  Future<void> submitComplaint() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.10:8000/api/complaints/staff-submit'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'guest_name': guestNameController.text.trim(),
          'room_number': roomNumberController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'category': category,
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'priority': priority,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Complaint submitted successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to submit complaint.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    guestNameController.dispose();
    roomNumberController.dispose();
    phoneController.dispose();
    emailController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff1583ff);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Guest Complaint'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _input(
                controller: guestNameController,
                label: 'Guest Name',
                icon: Icons.person,
                requiredField: true,
              ),

              _input(
                controller: roomNumberController,
                label: 'Room Number',
                icon: Icons.hotel,
              ),

              _input(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),

              _input(
                controller: emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),

              _dropdown(
                label: 'Category',
                icon: Icons.category,
                value: category,
                items: const [
                  'Maintenance',
                  'Housekeeping',
                  'Reception',
                  'Food & Beverage',
                  'Restaurant',
                  'Bar',
                  'Noise',
                  'Billing',
                  'WiFi',
                  'Other',
                ],
                onChanged: (value) {
                  setState(() => category = value!);
                },
              ),

              _dropdown(
                label: 'Priority',
                icon: Icons.priority_high,
                value: priority,
                items: const [
                  'low',
                  'medium',
                  'high',
                  'urgent',
                ],
                onChanged: (value) {
                  setState(() => priority = value!);
                },
              ),

              _input(
                controller: titleController,
                label: 'Complaint Title',
                icon: Icons.title,
                requiredField: true,
              ),

              _input(
                controller: descriptionController,
                label: 'Complaint Details',
                icon: Icons.notes,
                requiredField: true,
                maxLines: 5,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : submitComplaint,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isSubmitting ? 'Submitting...' : 'Submit Complaint',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xfff8fafc),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((word) =>
                      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
                  .join(' '),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xfff8fafc),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}