import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  String? _tempAvatar;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _nameController = TextEditingController(text: userProvider.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile(UserProvider provider) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your cosmic identity must have a name! ✨',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }
    provider.updateName(_nameController.text);
    if (_tempAvatar != null) {
      provider.updateAvatar(_tempAvatar!);
    }

    // Attempt backend sync
    provider.syncToApi().catchError((e) {
      debugPrint('Sync warning: $e');
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile synchronized with the universe. 🌌',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final currentAvatar = _tempAvatar ?? provider.profileImage;

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            title: Text(
              'EDIT IDENTITY',
              style: AppTextStyles.appBarTitle.copyWith(
                color: AppColors.textDark,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: AppColors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                40.verticalSpace,
                // ── Avatar Edit ──────────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            blurRadius: 30.r,
                            spreadRadius: 2.r,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70.r,
                        backgroundColor: AppColors.white,
                        backgroundImage: NetworkImage(currentAvatar),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tempAvatar =
                                'https://api.dicebear.com/7.x/avataaars/png?seed=${DateTime.now().millisecondsSinceEpoch}&backgroundColor=b6e3f4,c0aede,d1d4f9';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.glowPurple,
                                blurRadius: 10.r,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.white,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                40.verticalSpace,

                // ── Name Field ──────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MANIFESTOR NAME',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.4),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.sp,
                      ),
                    ),
                    12.verticalSpace,
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVeryLight,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.borderVeryLight,
                          width: 1.5.w,
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.transparent,
                          hintText: 'Enter your name...',
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            color: AppColors.purple.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 18.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                20.verticalSpace,

                // ── Save Button ──────────────────────────────────────────────
                PrimaryButton(
                  label: 'SAVE CHANGES ✨',
                  onPressed: () => _saveProfile(provider),
                ),

                20.verticalSpace,
                Text(
                  'Your digital identity is used across your manifestations.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textLightGrey,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
