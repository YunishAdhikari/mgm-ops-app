import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import 'attendance_screen.dart';

class AttendanceBufferPage extends StatefulWidget {
  final String authToken;

  const AttendanceBufferPage({
    super.key,
    required this.authToken,
  });

  @override
  State<AttendanceBufferPage> createState() => _AttendanceBufferPageState();
}

class _AttendanceBufferPageState extends State<AttendanceBufferPage> {
  bool isLoading = true;
  bool isClockedIn = false;

  DateTime? clockInTime;
  Duration workedDuration = Duration.zero;
  Timer? timer;

  static const primary = Color(0xffdc2626);
  static const background = Color(0xff09090b);
  static const cardColor = Color(0xff18181b);
  static const borderColor = Color(0xff27272a);
  static const mutedText = Color(0xffa1a1aa);

  @override
  void initState() {
    super.initState();
    fetchAttendanceStatus();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchAttendanceStatus() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          isClockedIn = data['is_clocked_in'] == true;

          if (isClockedIn && data['clock_in_at'] != null) {
            // clockInTime = DateTime.parse(data['clock_in_at']).toLocal();
            clockInTime = DateTime.parse(data['clock_in_at'].toString().replaceAll('Z', ''));
            workedDuration = DateTime.now().difference(clockInTime!);
            startLiveTimer();
          } else {
            timer?.cancel();
            clockInTime = null;
            workedDuration = Duration.zero;
          }
        });
      } else {
        showMessage(data['message'] ?? 'Failed to load attendance status.', false);
      }
    } catch (e) {
      showMessage('Network error: $e', false);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void startLiveTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || clockInTime == null) return;

      setState(() {
        workedDuration = DateTime.now().difference(clockInTime!);
      });
    });
  }

  Future<void> openQrScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceQrScannerPage(
          authToken: widget.authToken,
        ),
      ),
    );

    if (!mounted) return;
    fetchAttendanceStatus();
  }

  void showMessage(String message, bool success) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : primary,
      ),
    );
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primary),
            )
          : RefreshIndicator(
              color: primary,
              onRefresh: fetchAttendanceStatus,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _statusCard(),

                  const SizedBox(height: 24),

                  if (isClockedIn) _clockedInView() else _clockedOutView(),

                  const SizedBox(height: 28),

                  _mainButton(),

                  const SizedBox(height: 18),

                  _infoCard(),
                ],
              ),
            ),
    );
  }

  Widget _statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isClockedIn
                ? Colors.green.withOpacity(0.15)
                : primary.withOpacity(0.15),
            child: Icon(
              isClockedIn
                  ? Icons.check_circle_rounded
                  : Icons.logout_rounded,
              color: isClockedIn ? Colors.greenAccent : primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClockedIn ? 'You are clocked in' : 'You are clocked out',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isClockedIn
                      ? 'Your working timer is running live.'
                      : 'Scan the QR code to start your shift.',
                  style: const TextStyle(
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

  Widget _clockedInView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Live Hours Worked',
            style: TextStyle(
              color: mutedText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatDuration(workedDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            clockInTime == null
                ? ''
                : 'Clocked in at ${formatTime(clockInTime!)}',
            style: const TextStyle(
              color: mutedText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clockedOutView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            color: primary,
            size: 76,
          ),
          SizedBox(height: 18),
          Text(
            'Ready to start your shift?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap Clock In and scan the attendance QR code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: openQrScanner,
        icon: Icon(
          isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
        ),
        label: Text(
          isClockedIn ? 'Clock Out with QR' : 'Clock In with QR',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isClockedIn ? primary : Colors.green,
          foregroundColor: Colors.white,
          shadowColor: isClockedIn
              ? primary.withOpacity(0.45)
              : Colors.green.withOpacity(0.35),
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: mutedText,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'For security, every clock in and clock out requires scanning the live QR code.',
              style: TextStyle(
                color: mutedText,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}