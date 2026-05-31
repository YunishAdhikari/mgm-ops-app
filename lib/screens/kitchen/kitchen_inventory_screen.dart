import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';

import 'kitchen_stockIn_screen.dart';
import 'kitchen_sales_screen.dart';
import 'kitchen_buffet_sales_screen.dart';
import 'Kitchen_wastage_screen.dart';



class KitchenInventoryScreen extends StatefulWidget {
  const KitchenInventoryScreen({super.key});

  @override
  State<KitchenInventoryScreen> createState() => _KitchenInventoryScreenState();
}

class _KitchenInventoryScreenState extends State<KitchenInventoryScreen> {
  bool isLoading = true;
  List items = [];

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
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
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color stockColor(dynamic item) {
    final quantity = double.tryParse(item['quantity'].toString()) ?? 0;
    final minimum = double.tryParse(item['minimum_stock'].toString()) ?? 0;
    return quantity <= minimum ? AppColors.danger : AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Inventory'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchInventory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Menu Options
                  GridView.count(
                    crossAxisCount: isWide ?4 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 2.5 : 3.5,
                    children: [
                      _MenuCard(
                        icon: Icons.add_box_outlined,
                        title: 'Stock In',
                        subtitle: 'Add received stock',
                        color: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenStockInScreen()),
                        ).then((_) => fetchInventory()),
                      ),
                      _MenuCard(
                        icon: Icons.restaurant_menu,
                        title: 'Sales',
                        subtitle: 'Deduct recipe stock',
                        color: AppColors.warning,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenSalesScreen()),
                        ).then((_) => fetchInventory()),
                      ),
                      _MenuCard(
                        icon: Icons.food_bank_outlined,
                        title: 'Buffet Sales',
                        subtitle: 'Deduct buffet stock',
                        color: AppColors.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenBuffetSalesScreen()),
                        ).then((_) => fetchInventory()),
                      ),

                      _MenuCard(
                        icon: Icons.delete,
                        title: 'Wastage',
                        subtitle: 'Record wasted stock',
                        color: AppColors.secondary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KitchenWastageScreen()),
                        ).then((_) => fetchInventory()),
                      ),
                      
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Current Stock
                  const Text(
                    'Current Stock',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No inventory items found',
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ),
                    )
                                    else
                    ...items.map((item) => _InventoryCard(
                      item: item,
                      stockColor: stockColor(item),
                    )).toList(),
                ],
              ),
            ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final dynamic item;
  final Color stockColor;

  const _InventoryCard({required this.item, required this.stockColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2, color: stockColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Item',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item['category'] ?? 'Uncategorised',
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum: ${item['minimum_stock']} ${item['unit']}',
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['quantity']}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: stockColor,
                ),
              ),
              Text(
                item['unit'] ?? '',
                style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
