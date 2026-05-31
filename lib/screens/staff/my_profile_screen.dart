import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import 'package:flutter/services.dart';


class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool isLoading = true;
  bool isSaving = false;
  Uint8List? selectedImageBytes;
  XFile? selectedImage;
  final ImagePicker picker = ImagePicker();

  Map<String, dynamic>? user;
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> pickProfileImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    }
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        user = data['user'];
        phoneController.text = data['user']['phone'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateProfile() async {
    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/update'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['phone'] = phoneController.text.trim();

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

    setState(() => isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Profile updated')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() => selectedImage = null);
      fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user?['name'] ?? '';
    final email = user?['email'] ?? '';
    final role = user?['role']?['name'] ?? 'N/A';
    final department = user?['department']?['name'] ?? 'N/A';
    final imageUrl = user?['image_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickProfileImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: selectedImageBytes != null
                                      ? Image.memory(
                                          selectedImageBytes!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : Center(
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _ProfileRow('Role', role.toUpperCase()),
                        _ProfileRow('Department', department.toUpperCase()),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : updateProfile,
                            icon: isSaving
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : const Icon(Icons.save),
                            label: const Text('Update Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: TextStyle(color: AppColors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}