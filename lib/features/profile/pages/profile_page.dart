import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_button.dart';

/// User Profile & Account Settings Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            // User Avatar & Name
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder, width: 2),
                image: user?.profileImageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(user!.profileImageBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user?.profileImageBytes == null
                  ? const Icon(
                      Icons.person_rounded,
                      size: 56,
                      color: AppColors.textWhite,
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              user?.fullName.isNotEmpty == true ? user!.fullName : 'University Member',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email.isNotEmpty == true ? user!.email : 'No email available',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                user?.role.toFormattedString() ?? 'Student',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.navyAccent),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: AppColors.navyAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.navyAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Information Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.badge_outlined,
                      'Student / Staff ID',
                      user?.studentId?.isNotEmpty == true ? user!.studentId! : 'Not assigned',
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      Icons.phone_outlined,
                      'Contact Phone',
                      user?.phone?.isNotEmpty == true ? user!.phone! : 'Not provided',
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      Icons.school_outlined,
                      'Department',
                      user?.department?.isNotEmpty == true ? user!.department! : AppConstants.departmentName,
                    ),
                    const Divider(height: 20),
                    _infoRow(
                      Icons.account_balance_outlined,
                      'University',
                      user?.university?.isNotEmpty == true ? user!.university! : kUniversityName,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            AppButton(
              text: 'Log Out of Account',
              icon: Icons.logout_rounded,
              type: AppButtonType.outline,
              customColor: AppColors.danger,
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.navyAccent),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
