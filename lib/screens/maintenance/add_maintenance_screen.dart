import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';


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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      maxWidth: 1280,
                      maxHeight: 1280,
                    );
                    if (image != null) setState(() => selectedImage = image);
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
                      maxWidth: 1280,
                      maxHeight: 1280,
                    );
                    if (image != null) setState(() => selectedImage = image);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter task title')),
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
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: selectedImage!.name,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    setState(() => isLoading = false);

    if (!mounted) return;

    if (response.statusCode == 201 && data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Task added successfully')),
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
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Maintenance Task'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isDepartmentLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
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
                        'New Maintenance Task',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to submit a new task',
                        style: TextStyle(color: AppColors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Department
                      DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business),
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

                      // Priority
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => priority = value);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Location
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Room Number
                      TextField(
                        controller: roomController,
                        decoration: const InputDecoration(
                          labelText: 'Room Number',
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Image Upload
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 40,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedImage == null
                                    ? 'Tap to upload image'
                                    : selectedImage!.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : submitTask,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Submit Task'),
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
            ),
    );
  }
}