import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'apply_holiday_screen.dart';
import 'my_holiday_requests_screen.dart';
import 'change_password_screen.dart';
import 'my_profile_screen.dart';

class StaffDirectoryScreen extends StatelessWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Staff Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your staff options and requests',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StaffOption(
            icon: Icons.calendar_month_outlined,
            title: 'Apply Holiday',
            subtitle: 'Submit a new holiday request',
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyHolidayScreen())),
          ),
          _StaffOption(
            icon: Icons.history,
            title: 'Past Holidays',
            subtitle: 'View your holiday request history',
            color: AppColors.warning,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyHolidayRequestsScreen())),
          ),
          _StaffOption(
            icon: Icons.lock_reset,
            title: 'Change Password',
            subtitle: 'Update your account password',
            color: AppColors.success,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          _StaffOption(
            icon: Icons.person_outline,
            title: 'My Profile',
            subtitle: 'View and update your profile',
            color: AppColors.secondary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProfileScreen())),
          ),
        ],
      ),
    );
  }
}

class _StaffOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StaffOption({
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
