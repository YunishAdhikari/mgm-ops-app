import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendanceQrScannerPage extends StatefulWidget {
  final String authToken;

  const AttendanceQrScannerPage({
    super.key,
    required this.authToken,
  });

  @override
  State<AttendanceQrScannerPage> createState() =>
      _AttendanceQrScannerPageState();
}

class _AttendanceQrScannerPageState extends State<AttendanceQrScannerPage> {
  bool isProcessing = false;
  final MobileScannerController scannerController = MobileScannerController();

  Future<void> submitQrToken(String qrToken) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    await scannerController.stop();

    try {
        final response = await http.post(
          Uri.parse('https://mgmglasgow.com/api/attendance/scan-qr'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.authToken}',
          },
          body: jsonEncode({
            'token': qrToken.trim(),
          }),
        );

      Map<String, dynamic> data = {};

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (!mounted) return;

      final success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Attendance updated.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          isProcessing = false;
        });

        await scannerController.start();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        isProcessing = false;
      });

      await scannerController.start();
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Attendance QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (isProcessing) return;

              final barcode = capture.barcodes.firstOrNull;
              final token = barcode?.rawValue;

              if (token != null && token.isNotEmpty) {
                submitQrToken(token);
              }
            },
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Point your camera at the live QR code displayed in the staff room.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}