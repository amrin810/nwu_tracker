import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

/// Screen allowing the user to edit their profile details and photo
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _departmentController;
  late final TextEditingController _universityController;

  Uint8List? _profileImageBytes;
  bool _imageRemoved = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _studentIdController = TextEditingController(text: user?.studentId ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _departmentController = TextEditingController(
      text: user?.department ?? AppConstants.departmentName,
    );
    _universityController = TextEditingController(
      text: user?.university ?? kUniversityName,
    );
    _profileImageBytes = user?.profileImageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
          _imageRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      studentId: _studentIdController.text.trim(),
      phone: _phoneController.text.trim(),
      department: _departmentController.text.trim(),
      university: _universityController.text.trim(),
      profileImageBytes: _profileImageBytes,
      clearProfileImage: _imageRemoved,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Circular avatar with edit badge
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(55),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.cardBorder,
                                width: 2,
                              ),
                              image: _profileImageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_profileImageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImageBytes == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 56,
                                    color: AppColors.textWhite,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.navyAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_profileImageBytes != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _profileImageBytes = null;
                            _imageRemoved = true;
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        label: const Text(
                          'Remove photo',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'e.g. Abdullah Al Mamun',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Full Name cannot be empty' : null,
              ),
              const SizedBox(height: 14),

              // Email
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'student@nwu.edu.bd',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email cannot be empty';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Student / Staff ID
              AppTextField(
                controller: _studentIdController,
                label: 'Student / Staff ID',
                hint: 'e.g. CSE-22-0451',
                prefixIcon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Student / Staff ID cannot be empty'
                    : null,
              ),
              const SizedBox(height: 14),

              // Contact Phone
              AppTextField(
                controller: _phoneController,
                label: 'Contact Phone',
                hint: '01XXXXXXXXX',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Contact Phone cannot be empty';
                  }
                  final digitsOnly = RegExp(r'^[0-9]+$');
                  if (!digitsOnly.hasMatch(v.trim())) {
                    return 'Phone must be digits only';
                  }
                  if (v.trim().length < 11) {
                    return 'Phone must be at least 11 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Department
              AppTextField(
                controller: _departmentController,
                label: 'Department',
                hint: 'e.g. Computer Science & Engineering',
                prefixIcon: Icons.school_outlined,
              ),
              const SizedBox(height: 14),

              // University
              AppTextField(
                controller: _universityController,
                label: 'University',
                hint: 'e.g. North Western University',
                prefixIcon: Icons.account_balance_outlined,
              ),
              const SizedBox(height: 24),

              // Save Changes Button (filled navy)
              AppButton(
                text: 'Save Changes',
                icon: Icons.save_outlined,
                type: AppButtonType.primary,
                onPressed: _onSave,
              ),
              const SizedBox(height: 12),

              // Cancel Button
              AppButton(
                text: 'Cancel',
                type: AppButtonType.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

