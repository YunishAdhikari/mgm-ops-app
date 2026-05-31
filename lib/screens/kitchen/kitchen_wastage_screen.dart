import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class KitchenWastageScreen extends StatefulWidget {
  const KitchenWastageScreen({super.key});

  @override
  State<KitchenWastageScreen> createState() => _KitchenWastageScreenState();
}

class _KitchenWastageScreenState extends State<KitchenWastageScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List items = [];
  String? selectedItemId;
  String? reason;

  final quantityController = TextEditingController();
  final noteController = TextEditingController();

  final reasons = const [
    'expired',
    'spoiled',
    'damaged',
    'burnt',
    'overproduction',
    'staff_meal',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/kitchen/inventory'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        items = data['items'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitWastage() async {
    if (selectedItemId == null || quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select item and enter quantity')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/wastage'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'inventory_item_id': selectedItemId!,
        'quantity': quantityController.text.trim(),
        'reason': reason ?? '',
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);

    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Wastage recorded')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      selectedItemId = null;
      reason = null;
      quantityController.clear();
      noteController.clear();
      fetchItems();
      setState(() {});
    }
  }

  String cleanText(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        title: const Text('Kitchen Wastage'),
        backgroundColor: const Color(0xff1583ff),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 560 : double.infinity,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Wastage',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Record expired, damaged, spoiled, or wasted stock.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 22),

                      DropdownButtonFormField<String>(
                        value: selectedItemId,
                        isExpanded: true,
                        decoration: inputDecoration(
                          'Select Inventory Item',
                          Icons.inventory_2,
                        ),
                        items: items.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(
                              '${item['name']} (${item['quantity']} ${item['unit']})',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedItemId = value);
                        },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration(
                          'Quantity Wasted',
                          Icons.numbers,
                        ),
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: reason,
                        isExpanded: true,
                        decoration: inputDecoration(
                          'Reason',
                          Icons.warning,
                        ),
                        items: reasons.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(cleanText(item)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => reason = value);
                        },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: inputDecoration(
                          'Note optional',
                          Icons.note,
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submitWastage,
                          icon: const Icon(Icons.delete),
                          label: isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Record Wastage'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
}


InputDecoration inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}