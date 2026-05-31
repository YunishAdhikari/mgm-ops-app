import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';


class KitchenStockInScreen extends StatefulWidget {
  const KitchenStockInScreen({super.key});

  @override
  State<KitchenStockInScreen> createState() => _KitchenStockInScreenState();
}

class _KitchenStockInScreenState extends State<KitchenStockInScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List items = [];
  String? selectedItemId;
  final quantityController = TextEditingController();
  final noteController = TextEditingController();

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

  Future<void> submitStockIn() async {
    if (selectedItemId == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select item and enter quantity')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/inventory/stock-in'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'inventory_item_id': selectedItemId!,
        'quantity': quantityController.text.trim(),
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Stock updated')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      quantityController.clear();
      noteController.clear();
      selectedItemId = null;
      fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock In'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _FormScreen(
              children: [
                const Text(
                  'Add Stock',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Record received kitchen stock', style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),

                // Select Item
                DropdownButtonFormField<String>(
                  value: selectedItemId,
                  decoration: const InputDecoration(
                    labelText: 'Select Item',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: items.map<DropdownMenuItem<String>>((item) {
                    return DropdownMenuItem<String>(
                      value: item['id'].toString(),
                      child: Text('${item['name']} (${item['unit']})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedItemId = value),
                ),
                const SizedBox(height: 14),

                // Quantity
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers),
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
                    onPressed: isSubmitting ? null : submitStockIn,
                    icon: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.save),
                    label: const Text('Save Stock In'),
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