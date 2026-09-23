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
  bool _isSaving = false;
  bool _lastHasChanges = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _nameController = TextEditingController(text: userProvider.name);
    _nameController.addListener(_onNameChanged);

    // Precache all 30 memojis in background so selecting/switching is instant (0ms)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final m in UserProvider.memojiList) {
        precacheImage(
          NetworkImage(
            'https://cdn.jsdelivr.net/gh/alohe/memojis@main/png/$m.png',
          ),
          context,
        );
      }
    });
  }

  void _onNameChanged() {
    final current = _hasChanges(context.read<UserProvider>());
    if (current != _lastHasChanges) {
      _lastHasChanges = current;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _showAvatarPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              16.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHOOSE YOUR AVATAR',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textDark,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        'Select a cosmic spirit for your journey',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final randomUrl = UserProvider.generateRandomAvatarUrl();
                      setState(() => _tempAvatar = randomUrl);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(
                      Icons.shuffle_rounded,
                      size: 16,
                      color: AppColors.purple,
                    ),
                    label: Text(
                      'Random ✨',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 14.w,
                    mainAxisSpacing: 14.h,
                  ),
                  itemCount: UserProvider.memojiList.length,
                  itemBuilder: (context, index) {
                    final memo = UserProvider.memojiList[index];
                    final url =
                        'https://cdn.jsdelivr.net/gh/alohe/memojis@main/png/$memo.png';
                    final isSelected =
                        (_tempAvatar ??
                            context.read<UserProvider>().profileImage) ==
                        url;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _tempAvatar = url);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.purple.withValues(alpha: 0.1)
                              : AppColors.surfaceVeryLight,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.purple
                                : AppColors.borderLight,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person_rounded,
                              color: AppColors.purple,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasChanges(UserProvider provider) {
    final inputName = _nameController.text.trim();
    if (inputName.isEmpty) return false;

    final nameChanged = inputName != provider.name.trim();
    final avatarChanged =
        _tempAvatar != null && _tempAvatar != provider.profileImage;

    return nameChanged || avatarChanged;
  }

  Future<void> _saveProfile(UserProvider provider) async {
    if (!_hasChanges(provider) || _isSaving) return;

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
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

    setState(() => _isSaving = true);
    provider.updateName(trimmedName);
    if (_tempAvatar != null) {
      provider.updateAvatar(_tempAvatar!);
    }

    try {
      await provider.syncToApi();
      if (!mounted) return;
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
    } catch (e) {
      debugPrint('Sync warning: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved locally. Changes will sync once connected. ✨',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                36.verticalSpace,
                // ── Avatar Edit ──────────────────────────────────────────────
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showAvatarPickerSheet(context),
                      child: Container(
                        width: 140.r,
                        height: 140.r,
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
                        child: ClipOval(
                          child: Container(
                            color: AppColors.white,
                            child: Image.network(
                              currentAvatar,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 28.r,
                                        height: 28.r,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.purple,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person_rounded,
                                    size: 60.r,
                                    color: AppColors.purple,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showAvatarPickerSheet(context),
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
                            Icons.auto_awesome,
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
                        textCapitalization: TextCapitalization.words,
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
                  isLoading: _isSaving,
                  onPressed: _hasChanges(provider) && !_isSaving
                      ? () => _saveProfile(provider)
                      : null,
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
