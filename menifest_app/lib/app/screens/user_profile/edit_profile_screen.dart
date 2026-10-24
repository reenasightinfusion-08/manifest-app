import 'package:flutter/material.dart';
import 'package:menifest_app/app/services/user_provider.dart';
import 'package:menifest_app/app/widgets/primary_button.dart';
import 'package:menifest_app/core/common/core.dart';
import 'package:provider/provider.dart';

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
    final isTablet = context.isTablet;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      constraints: isTablet ? const BoxConstraints(maxWidth: 640.0) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isTablet ? 24.0 : 28.r),
        ),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * (isTablet ? 0.60 : 0.65),
          padding: isTablet
              ? const EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 24.0)
              : EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            children: [
              // Handle
              Container(
                width: isTablet ? 48.0 : 40.w,
                height: isTablet ? 4.0 : 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              isTablet ? const SizedBox(height: 16.0) : 16.verticalSpace,
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
                          fontSize: isTablet ? 14.0 : 14.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      isTablet ? const SizedBox(height: 4.0) : 4.verticalSpace,
                      Text(
                        'Select a cosmic spirit for your journey',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGrey,
                          fontSize: isTablet ? 12.5 : 12.sp,
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
                      size: 16.0,
                      color: AppColors.purple,
                    ),
                    label: Text(
                      'Random ✨',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 13.0 : 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
              isTablet ? const SizedBox(height: 16.0) : 16.verticalSpace,
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 6 : 4,
                    crossAxisSpacing: isTablet ? 14.0 : 14.w,
                    mainAxisSpacing: isTablet ? 14.0 : 14.h,
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
                        padding: EdgeInsets.all(isTablet ? 4.0 : 4.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.purple.withValues(alpha: 0.1)
                              : AppColors.surfaceVeryLight,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.purple
                                : AppColors.borderLight,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person_rounded,
                              color: AppColors.purple,
                              size: isTablet ? 24.0 : 24.sp,
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
        if (context.isTablet) {
          return _buildTabletLayout(context, provider);
        }

        return _buildPhoneLayout(context, provider);
      },
    );
  }

  // ── Tablet Layout ──────────────────────────────────────────────────────────
  Widget _buildTabletLayout(BuildContext context, UserProvider provider) {
    final currentAvatar = _tempAvatar ?? provider.profileImage;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF8FE),
              Color(0xFFF3ECFA),
              Color(0xFFFCF0F5),
              Color(0xFFF4EDFE),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow orbs
            Positioned(
              top: -60.0,
              right: -40.0,
              child: Container(
                width: 320.0,
                height: 320.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.10),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40.0,
              left: -30.0,
              child: Container(
                width: 280.0,
                height: 280.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.pink.withValues(alpha: 0.08),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? 820.0 : 720.0,
                ),
                child: Container(
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.08),
                        blurRadius: 32.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 10.0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildTabletTopBar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            isLandscape ? 48.0 : 36.0,
                            isLandscape ? 28.0 : 36.0,
                            isLandscape ? 48.0 : 36.0,
                            36.0,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 520.0,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12.0),
                                  // ── Avatar Edit ──
                                  Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            _showAvatarPickerSheet(context),
                                        child: Container(
                                          width: 140.0,
                                          height: 140.0,
                                          padding: const EdgeInsets.all(4.0),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: AppColors.primaryGradient,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.purple
                                                    .withValues(alpha: 0.18),
                                                blurRadius: 30.0,
                                                spreadRadius: 2.0,
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
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 28.0,
                                                          height: 28.0,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color: AppColors
                                                                .purple,
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
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.person_rounded,
                                                      size: 60.0,
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
                                          onTap: () =>
                                              _showAvatarPickerSheet(context),
                                          child: Container(
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color: AppColors.purple,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.glowPurple,
                                                  blurRadius: 10.0,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome,
                                              color: AppColors.white,
                                              size: 20.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12.0),
                                  GestureDetector(
                                    onTap: () =>
                                        _showAvatarPickerSheet(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14.0,
                                        vertical: 6.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          16.0,
                                        ),
                                        border: Border.all(
                                          color: AppColors.purple.withValues(
                                            alpha: 0.18,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.edit_rounded,
                                            size: 14.0,
                                            color: AppColors.purple,
                                          ),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            'Change Avatar',
                                            style: AppTextStyles.label.copyWith(
                                              color: AppColors.purple,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 36.0),

                                  // ── Name Field ──
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MANIFESTOR NAME',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.textDark.withValues(
                                            alpha: 0.4,
                                          ),
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12.0),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVeryLight,
                                          borderRadius: BorderRadius.circular(
                                            20.0,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderVeryLight,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _nameController,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                color: AppColors.textDark,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16.0,
                                              ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppColors.transparent,
                                            hintText: 'Enter your name...',
                                            prefixIcon: Icon(
                                              Icons.person_rounded,
                                              color: AppColors.purple
                                                  .withValues(alpha: 0.5),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 20.0,
                                                  vertical: 18.0,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 28.0),

                                  // ── Save Button ──
                                  PrimaryButton(
                                    label: 'SAVE CHANGES ✨',
                                    height: 54.0,
                                    fontSize: 16.0,
                                    isLoading: _isSaving,
                                    onPressed:
                                        _hasChanges(provider) && !_isSaving
                                        ? () => _saveProfile(provider)
                                        : null,
                                  ),

                                  const SizedBox(height: 20.0),
                                  Text(
                                    'Your digital identity is used across your manifestations.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textLightGrey,
                                      fontSize: 13.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.purple.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label: 'Go back to profile',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(22.0),
                child: Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 2.0),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textDark,
                        size: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EDIT IDENTITY',
                style: AppTextStyles.appBarTitle.copyWith(
                  color: AppColors.textDark,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  'COSMIC',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 42.0),
        ],
      ),
    );
  }

  // ── Phone Layout (Preserved 100% Unchanged) ──────────────────────────────
  Widget _buildPhoneLayout(BuildContext context, UserProvider provider) {
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 28.r,
                                height: 28.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.purple,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Icon(
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
  }
}
