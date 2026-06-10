import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

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

  static const primary = Color(0xffdc2626);
  static const background = Color(0xff09090b);
  static const cardColor = Color(0xff18181b);
  static const borderColor = Color(0xff27272a);
  static const mutedText = Color(0xffa1a1aa);

  Future<void> submitComplaint() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complaints/staff-submit'),
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
            backgroundColor: primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: primary,
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
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Guest Complaint',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _headerCard(),

              _input(
                controller: guestNameController,
                label: 'Guest Name',
                icon: Icons.person_rounded,
                requiredField: true,
              ),

              _input(
                controller: roomNumberController,
                label: 'Room Number',
                icon: Icons.hotel_rounded,
              ),

              _input(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),

              _input(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              _dropdown(
                label: 'Category',
                icon: Icons.category_rounded,
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
                icon: Icons.priority_high_rounded,
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
                icon: Icons.title_rounded,
                requiredField: true,
              ),

              _input(
                controller: descriptionController,
                label: 'Complaint Details',
                icon: Icons.notes_rounded,
                requiredField: true,
                maxLines: 5,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 56,
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
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    isSubmitting ? 'Submitting...' : 'Submit Complaint',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 12,
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withOpacity(0.45),
                    disabledForegroundColor: Colors.white70,
                    shadowColor: primary.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0x22dc2626),
            child: Icon(
              Icons.report_problem_rounded,
              color: primary,
              size: 28,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Complaint Form',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Report guest issues quickly and clearly.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        style: const TextStyle(color: Colors.white),
        cursorColor: primary,
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
          labelStyle: const TextStyle(color: mutedText),
          prefixIcon: Icon(icon),
          prefixIconColor: primary,
          filled: true,
          fillColor: cardColor,
          errorStyle: const TextStyle(
            color: Color(0xffff8a8a),
            fontWeight: FontWeight.w600,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.8),
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
        dropdownColor: cardColor,
        iconEnabledColor: primary,
        style: const TextStyle(color: Colors.white),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map(
                    (word) => word.isEmpty
                        ? word
                        : word[0].toUpperCase() + word.substring(1),
                  )
                  .join(' '),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: mutedText),
          prefixIcon: Icon(icon),
          prefixIconColor: primary,
          filled: true,
          fillColor: cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}