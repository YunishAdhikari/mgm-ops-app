import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';


class KitchenBuffetSalesScreen extends StatefulWidget {
  const KitchenBuffetSalesScreen({super.key});

  @override
  State<KitchenBuffetSalesScreen> createState() =>
      _KitchenBuffetSalesScreenState();
}

class _KitchenBuffetSalesScreenState extends State<KitchenBuffetSalesScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List buffets = [];
  String? selectedBuffetId;
  final paxController = TextEditingController();
  final noteController = TextEditingController();
  DateTime saleDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchBuffets();
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchBuffets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kitchen/buffets'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          buffets = data['buffets'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickSaleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: saleDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => saleDate = picked);
  }

  Future<void> submitBuffetSale() async {
    if (selectedBuffetId == null || paxController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select buffet and enter pax')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/buffets/$selectedBuffetId/sale'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'sale_date': formatDate(saleDate),
        'pax': paxController.text.trim(),
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Buffet sale recorded')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      paxController.clear();
      noteController.clear();
      selectedBuffetId = null;
      saleDate = DateTime.now();
      fetchBuffets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buffet Sales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _FormScreen(
              children: [
                const Text(
                  'Record Buffet Sale',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Enter buffet pax sold to deduct inventory', style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),

                // Select Buffet
                DropdownButtonFormField<String>(
                  value: selectedBuffetId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Buffet',
                    prefixIcon: Icon(Icons.food_bank_outlined),
                  ),
                  items: buffets.map<DropdownMenuItem<String>>((buffet) {
                    return DropdownMenuItem<String>(
                      value: buffet['id'].toString(),
                      child: Text(buffet['name'] ?? 'Buffet'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedBuffetId = value),
                ),
                const SizedBox(height: 14),

                // Sale Date
                InkWell(
                  onTap: pickSaleDate,
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
                            Text('Sale Date', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(formatDate(saleDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Pax Sold
                TextField(
                  controller: paxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pax Sold',
                    prefixIcon: Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 14),

                // Note
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    prefixIcon: const Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : submitBuffetSale,
                    icon: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.save),
                    label: const Text('Save Buffet Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

//foam screen
class _FormScreen extends StatelessWidget {
  final List<Widget> children;

  const _FormScreen({required this.children});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Center(
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
            children: children,
          ),
        ),
      ),
    );
  }
}