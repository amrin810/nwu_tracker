import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

/// User Registration Page supporting Student, Driver, and Conductor accounts
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Dynamic ID label matching the currently selected role
  String get _idLabel {
    switch (_selectedRole) {
      case UserRole.student:
        return 'Student ID';
      case UserRole.driver:
        return 'Driver ID';
      case UserRole.conductor:
        return 'Conductor ID';
      default:
        return 'ID';
    }
  }

  /// Dynamic ID hint matching the currently selected role
  String get _idHint {
    switch (_selectedRole) {
      case UserRole.student:
        return 'e.g. CSE-22-0451';
      case UserRole.driver:
        return 'e.g. DRV-001';
      case UserRole.conductor:
        return 'e.g. CND-001';
      default:
        return 'Enter your ID';
    }
  }

  /// Dispatches the newly registered user to the appropriate screen or dashboard based on role.
  /// Prepares the role-based routing architecture for future Driver and Conductor modules.
  void _navigateToRoleDashboard(UserRole role) {
    switch (role) {
      case UserRole.student:
        // Default Student interface: Main live tracking shell with stops & schedules
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainShell);
        break;

      case UserRole.driver:
        // TODO: Future Driver Dashboard for broadcasting real-time GPS coordinates
        // For now, routes safely to the main tracking shell
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainShell);
        break;

      case UserRole.conductor:
        // TODO: Future Conductor Portal for managing student RFID tap-in & attendance
        // For now, routes safely to the main tracking shell
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainShell);
        break;

      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
        break;
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      userId: _idController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    if (success && mounted) {
      _navigateToRoleDashboard(_selectedRole);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Register Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join Campus Transportation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create an account with your university credentials',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Full Name
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. Abdullah Al Mamun',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Email
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'name@university.edu.bd',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Valid email required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Dynamic Role-Based ID Field
                AppTextField(
                  controller: _idController,
                  label: _idLabel,
                  hint: _idHint,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your $_idLabel'
                      : null,
                ),
                const SizedBox(height: 14),

                // Phone
                AppTextField(
                  controller: _phoneController,
                  label: 'Contact Phone Number',
                  hint: '01XXXXXXXXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                // Account Role Dropdown
                const Text(
                  'Account Role',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.people_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.student,
                      child: Text('Student'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.driver,
                      child: Text('Driver'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.conductor,
                      child: Text('Conductor'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null && val != _selectedRole) {
                      setState(() {
                        _selectedRole = val;
                        _idController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Password
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 24),

                // Submit Button
                AppButton(
                  text: 'Create Account',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),

                // Already registered link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Already have an account? Sign In'),
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
