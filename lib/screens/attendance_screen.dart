import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  String status = 'clocked_out';
  Map? log;
  Future<Position?> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enable location service')),
    );
    return null;
  }

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location permission permanently denied')),
    );
    return null;
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/attendance/status'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        status = data['status'] ?? 'clocked_out';
        log = data['log'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

 Future<void> clockAction(String type) async {
  setState(() => isSubmitting = true);

  final position = await getCurrentLocation();

  if (position == null) {
    setState(() => isSubmitting = false);
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final endpoint = type == 'in'
      ? '$baseUrl/attendance/clock-in'
      : '$baseUrl/attendance/clock-out';

  final response = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
    },
  );

  final data = jsonDecode(response.body);

  setState(() => isSubmitting = false);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(data['message'] ?? 'Attendance updated')),
  );

  if (response.statusCode == 200 && data['success'] == true) {
    fetchStatus();
  }
}

  String showTime(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (!text.contains('T')) return text;
    return text.substring(11, 16);
  }

  @override
  Widget build(BuildContext context) {
    final isClockedIn = status == 'clocked_in';

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(22),
                  decoration: cardDecoration(),
                  child: Column(
                    children: [
                      Icon(
                        isClockedIn ? Icons.check_circle : Icons.access_time,
                        size: 74,
                        color: isClockedIn ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 18),

                      Text(
                        isClockedIn ? 'You are clocked in' : 'You are clocked out',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        isClockedIn
                            ? 'Remember to clock out before leaving work.'
                            : 'Clock in when you arrive at the hotel.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 26),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xfff9fafb),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _attendanceRow(
                              'Clock In',
                              showTime(log?['clock_in_at']),
                            ),
                            const Divider(),
                            _attendanceRow(
                              'Clock Out',
                              showTime(log?['clock_out_at']),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () => clockAction(isClockedIn ? 'out' : 'in'),
                          icon: Icon(
                            isClockedIn ? Icons.logout : Icons.login,
                          ),
                          label: isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isClockedIn ? 'Clock Out' : 'Clock In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isClockedIn ? Colors.red : Colors.green,
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
            ),
    );
  }

  Widget _attendanceRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}