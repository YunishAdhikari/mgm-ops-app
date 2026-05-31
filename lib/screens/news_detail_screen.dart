import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news['image_url'] != null)
              Image.network(
                news['image_url'],
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.grey),
                      const SizedBox(width: 6),
                      Text(
                        (news['created_at'] ?? '').toString().substring(0, 10),
                        style: TextStyle(color: AppColors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    news['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Color(0xff374151),
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