import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../expenses/presentation/widgets/user_avatar.dart';
import '../providers/auth_provider.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _selectedAvatarUrl;

  final List<String> _avatarPresets = [
    '🦊',
    '🐱',
    '🦁',
    '🐯',
    '🐨',
    '🐼',
    '🐰',
    '🐶',
    '🦄',
    '🐸',
    '🐙',
    '🐵',
    '🚗',
    '✈️',
    '🎮',
    '🏀',
    '🍕',
    '🍩',
    '🥑',
    '💼',
    '💡',
    '🔥',
    '✨',
    '🍀',
  ];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedAvatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    final urlController = TextEditingController(
      text:
          (_selectedAvatarUrl != null && _selectedAvatarUrl!.startsWith('http'))
          ? _selectedAvatarUrl
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose Avatar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use emoji presets or enter a custom image URL.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: AppTheme.darkSlateVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Emoji presets grid
                  SizedBox(
                    height: 180,
                    child: GridView.builder(
                      itemCount: _avatarPresets.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                      itemBuilder: (context, index) {
                        final emoji = _avatarPresets[index];
                        final isSelected = _selectedAvatarUrl == emoji;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedAvatarUrl = emoji;
                            });
                            setState(() {
                              _selectedAvatarUrl = emoji;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.primaryFixed
                                  : const Color(0xFFF1F5F9),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL input
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Or Custom Image URL',
                      hintText: 'https://example.com/avatar.jpg',
                      prefixIcon: Icon(Icons.link),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        _selectedAvatarUrl = val.trim().isEmpty
                            ? null
                            : val.trim();
                      });
                      setState(() {
                        _selectedAvatarUrl = val.trim().isEmpty
                            ? null
                            : val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (urlController.text.trim().isNotEmpty) {
                              setState(() {
                                _selectedAvatarUrl = urlController.text.trim();
                              });
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Select'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Check if user has made any changes
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Call update API
    final success = await authProvider.updateProfile(
      displayName: name,
      email: user?.authProvider == 'GOOGLE' ? null : email,
      avatarUrl: _selectedAvatarUrl,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to update profile.',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final double formWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;
    final isGoogleUser = user?.authProvider == 'GOOGLE';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: responsive.scaleFont(18),
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkSlate),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.screenPadding,
          child: Center(
            child: SizedBox(
              width: formWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Section with Edit button
                  Stack(
                    children: [
                      UserAvatar(
                        avatarUrl: _selectedAvatarUrl,
                        displayName: _nameController.text.isNotEmpty
                            ? _nameController.text
                            : 'U',
                        size: 110,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showAvatarPicker,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form fields card container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            enabled: !isGoogleUser,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'email@domain.com',
                              prefixIcon: const Icon(Icons.mail_outline),
                              fillColor: isGoogleUser
                                  ? const Color(0xFFE2E8F0)
                                  : null,
                            ),
                            validator: (val) {
                              if (isGoogleUser) return null;
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(val.trim())) {
                                return 'Invalid email format';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          if (isGoogleUser) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryFixed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: AppTheme.tertiary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Email is connected to Google and cannot be changed.',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        color: AppTheme.darkSlateVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 24),

                          // Submit Button
                          authProvider.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _handleSave,
                                  child: const Text('Save Changes'),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
