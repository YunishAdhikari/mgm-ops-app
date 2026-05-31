import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';

class KitchenSalesScreen extends StatefulWidget {
  const KitchenSalesScreen({super.key});

  @override
  State<KitchenSalesScreen> createState() => _KitchenSalesScreenState();
}

class _KitchenSalesScreenState extends State<KitchenSalesScreen> {
  bool isLoading = true;
  bool isSubmitting = false;

  List recipes = [];
  String? selectedRecipeId;
  final quantityController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kitchen/recipes'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          recipes = data['recipes'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitSale() async {
    if (selectedRecipeId == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select recipe and enter quantity')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/kitchen/recipes/$selectedRecipeId/sale'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'quantity': quantityController.text.trim(),
        'note': noteController.text.trim(),
      },
    );

    final data = jsonDecode(response.body);
    setState(() => isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Sale recorded')),
    );

    if (response.statusCode == 200 && data['success'] == true) {
      quantityController.clear();
      noteController.clear();
      selectedRecipeId = null;
      fetchRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Sales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _FormScreen(
              children: [
                const Text(
                  'Record Recipe Sale',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Select recipe and enter quantity sold', style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 24),

                // Select Recipe
                DropdownButtonFormField<String>(
                  value: selectedRecipeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Recipe',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  items: recipes.map<DropdownMenuItem<String>>((recipe) {
                    return DropdownMenuItem<String>(
                      value: recipe['id'].toString(),
                      child: Text(recipe['name'] ?? 'Recipe'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedRecipeId = value),
                ),
                const SizedBox(height: 14),

                // Quantity
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity Sold',
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
                    onPressed: isSubmitting ? null : submitSale,
                    icon: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.save),
                    label: const Text('Save Sale'),
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