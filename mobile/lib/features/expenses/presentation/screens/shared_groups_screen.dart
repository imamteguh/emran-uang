import 'dart:async';
import 'package:emran_uang/features/expenses/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class SharedGroupsScreen extends StatefulWidget {
  const SharedGroupsScreen({super.key});

  @override
  State<SharedGroupsScreen> createState() => _SharedGroupsScreenState();
}

class _SharedGroupsScreenState extends State<SharedGroupsScreen> {
  bool _isInit = true;
  bool _isActionLoading = false;
  String? _processingInviteId;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      context.read<DashboardBloc>().add(const DashboardFetchSharedGroupsRequested());
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardBloc>().state;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState.currentUser;
    final responsive = ResponsiveHelper(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
              onPressed: _isActionLoading
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Shared Groups',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: responsive.scaleFont(18),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.primary),
                onPressed: _isActionLoading
                    ? null
                    : () => _refreshIndicatorKey.currentState?.show(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () async {
                context.read<DashboardBloc>().add(const DashboardFetchSharedGroupsRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.marginMobile,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Create New Group Card
                    _buildCreateGroupCard(context, provider),
                    const SizedBox(height: 24),

                    // 2. Pending Invitations Section
                    if (provider.pendingInvites.isNotEmpty) ...[
                      _buildPendingInvitations(
                        context,
                        provider,
                        responsive,
                        currentUser?.id,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 3. Active Shared Groups Section
                    _buildActiveGroups(
                      context,
                      provider,
                      responsive,
                      currentUser?.id,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isActionLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(51),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Create Group Card ─────────────────────────────────────────────────────

  Widget _buildCreateGroupCard(
    BuildContext context,
    DashboardState provider,
  ) {
    return Container(
      decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
      child: ClipRRect(
        borderRadius: AppTheme.roundedBorder,
        child: Material(
          color: AppTheme.primaryContainer,
          child: InkWell(
            onTap: () => _showCreateGroupBottomSheet(context),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Group',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share expenses with friends',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ],
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

  void _showCreateGroupBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create New Group',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set up a shared group. We will automatically create a Shared Wallet for you and invite your friend.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppTheme.darkSlateVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        enabled: !isSubmitting,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.group_work_outlined),
                          hintText: 'Group Name (e.g. Housemates, Trip)',
                          labelText: 'GROUP NAME',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a group name';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length < 3) {
                            return 'Group name must be at least 3 characters';
                          }
                          if (trimmed.length > 50) {
                            return 'Group name cannot exceed 50 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline),
                          hintText: 'friend@email.com',
                          labelText: 'INVITE EMAIL',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email to invite';
                          }
                          final trimmed = value.trim();
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(trimmed)) {
                            return 'Please enter a valid email address';
                          }
                          final currentUser =
                              context.read<AuthBloc>().state.currentUser;
                          if (currentUser != null &&
                              trimmed.toLowerCase() ==
                                  currentUser.email.toLowerCase().trim()) {
                            return 'You cannot invite yourself';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setSheetState(() {
                                      isSubmitting = true;
                                    });
                                    final completer = Completer<String?>();
                                    context.read<DashboardBloc>().add(
                                      DashboardSendInviteRequested(
                                        email: emailController.text.trim(),
                                        groupName: nameController.text.trim(),
                                        completer: completer,
                                      ),
                                    );
                                    final errorMsg = await completer.future;
                                    if (context.mounted) {
                                      if (errorMsg == null) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Group created and invitation sent!',
                                            ),
                                          ),
                                        );
                                      } else {
                                        setSheetState(() {
                                          isSubmitting = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMsg),
                                            backgroundColor: AppTheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Create Group',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Pending Invitations ───────────────────────────────────────────────────

  Widget _buildPendingInvitations(
    BuildContext context,
    DashboardState provider,
    ResponsiveHelper responsive,
    String? currentUserId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Invitations',
              style: AppTheme.headlineSm.copyWith(
                fontSize: responsive.scaleFont(18),
                color: AppTheme.darkSlate,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryContainer.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.pendingInvites.length} New',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.tertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.pendingInvites.length,
          itemBuilder: (context, index) {
            final invite = provider.pendingInvites[index];
            final senderName = invite['sender']?['displayName'] ?? 'Someone';
            final isSentByMe = invite['senderId'] == currentUserId;
            final groupName = invite['group']?['name'] ?? 'Shared Group';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
                border: const Border(
                  left: BorderSide(
                    color: AppTheme.tertiaryContainer,
                    width: 4.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer.withAlpha(70),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.celebration,
                      color: AppTheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSentByMe
                              ? 'Invited: ${invite['receiverEmail']}'
                              : 'Invited by $senderName',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSentByMe)
                    _processingInviteId == invite['id']
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              IconButton(
                                onPressed: _processingInviteId != null
                                    ? null
                                    : () async {
                                        setState(() {
                                          _processingInviteId = invite['id'];
                                        });
                                        final completer = Completer<bool>();
                                        context.read<DashboardBloc>().add(
                                          DashboardRejectInviteRequested(invite['id'], completer),
                                        );
                                        final success = await completer.future;
                                        if (context.mounted) {
                                          setState(() {
                                            _processingInviteId = null;
                                          });
                                          if (success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Invitation rejected',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  shape: const CircleBorder(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: _processingInviteId != null
                                    ? null
                                    : () async {
                                        setState(() {
                                          _processingInviteId = invite['id'];
                                        });
                                        final completer = Completer<bool>();
                                        context.read<DashboardBloc>().add(
                                          DashboardAcceptInviteRequested(invite['id'], completer),
                                        );
                                        final success = await completer.future;
                                        if (context.mounted) {
                                          setState(() {
                                            _processingInviteId = null;
                                          });
                                          if (success) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Invitation accepted! Shared wallet active.',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(
                                  Icons.check,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primary.withAlpha(
                                    20,
                                  ),
                                  shape: const CircleBorder(),
                                ),
                              ),
                            ],
                          )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sent Pending',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Active Groups ─────────────────────────────────────────────────────────

  Widget _buildActiveGroups(
    BuildContext context,
    DashboardState provider,
    ResponsiveHelper responsive,
    String? currentUserId,
  ) {
    if (provider.sharedGroups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.roundedBorder,
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No active shared groups',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a group above and invite someone to track shared expenses together.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                color: AppTheme.darkSlateVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final topColors = [
      AppTheme.primaryFixedDim,
      AppTheme.tertiaryFixedDim,
      AppTheme.secondaryFixedDim,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Shared Groups',
          style: AppTheme.headlineSm.copyWith(
            fontSize: responsive.scaleFont(18),
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.sharedGroups.length,
          itemBuilder: (context, index) {
            final groupItem = provider.sharedGroups[index];
            final group = groupItem['group'];
            final myRole = groupItem['myRole'];
            final groupName = group['name'] ?? 'Shared Group';
            final membersList = group['members'] as List? ?? [];
            final stripeColor = topColors[index % topColors.length];

            final activeBillsCount = group['activeBillsCount'] ?? 0;
            final String subtitleText =
                '${membersList.length} members • $activeBillsCount active bill${activeBillsCount == 1 ? "" : "s"}';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  splashColor: stripeColor.withAlpha(50),
                  highlightColor: stripeColor.withAlpha(20),
                  onTap: () {
                    // Navigate to group details in the future
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: stripeColor.withAlpha(51), // approx 20% opacity
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(color: stripeColor, width: 4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.group,
                                    size: 14,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    subtitleText,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildOverlappingAvatars(membersList),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppTheme.onSurfaceVariant,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              splashRadius: 20,
                              onPressed: () => _showGroupActionsBottomSheet(
                                context,
                                group,
                                myRole,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverlappingAvatars(List<dynamic> members) {
    final displayMembers = members.take(3).toList();
    final remainingCount = members.length - displayMembers.length;
    const double avatarSize = 32.0; // w-8 h-8 (32px)
    const double spacing = 20.0; // 32px size - 12px overlap (-space-x-3)

    return SizedBox(
      height: avatarSize,
      width: displayMembers.isEmpty
          ? 0.0
          : (remainingCount > 0
              ? (displayMembers.length * spacing) + avatarSize
              : ((displayMembers.length - 1) * spacing) + avatarSize),
      child: Stack(
        children: [
          // Draw members in forward order so the left member is at the bottom, 
          // and subsequent members overlap towards the right.
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * spacing,
              child: _buildAvatarCircle(displayMembers[i]['user'], avatarSize),
            ),
          
          // Draw remaining count last so it sits at the very top of the stack
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * spacing,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(dynamic user, double size) {
    if (user == null) return const SizedBox();
    final name = user['displayName'] ?? '';
    final avatarUrl = user['avatarUrl'];

    return UserAvatar(avatarUrl: avatarUrl, displayName: name, size: size);
  }

  void _showGroupActionsBottomSheet(
    BuildContext context,
    dynamic group,
    dynamic myRole,
  ) {
    final groupName = group['name'] ?? 'Shared Group';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          myRole == 'OWNER' ? 'Group Owner' : 'Group Member',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: AppTheme.error,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Leave Group',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.error,
                  ),
                ),
                subtitle: Text(
                  'Exit from this group and its shared expenses',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleLeaveGroup(group);
                },
              ),
              if (myRole == 'OWNER') ...[
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_forever,
                      color: AppTheme.error,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Delete Group',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.error,
                    ),
                  ),
                  subtitle: Text(
                    'Permanently delete group and all associated records',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handleDeleteGroup(group);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLeaveGroup(dynamic group) async {
    final confirm = await _showConfirmDialog(
      context,
      'Leave Group',
      'Are you sure you want to leave this shared group?',
    );
    if (confirm == true && mounted) {
      setState(() {
        _isActionLoading = true;
      });
      final completer = Completer<bool>();
      context.read<DashboardBloc>().add(
        DashboardLeaveGroupRequested(group['id'], completer),
      );
      final success = await completer.future;
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Left the group successfully'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteGroup(dynamic group) async {
    final confirm = await _showConfirmDialog(
      context,
      'Delete Group',
      'Are you sure you want to delete this shared group and all its associated data? This action is permanent and cannot be undone.',
    );
    if (confirm == true && mounted) {
      setState(() {
        _isActionLoading = true;
      });
      final completer = Completer<bool>();
      context.read<DashboardBloc>().add(
        DashboardDeleteGroupRequested(group['id'], completer),
      );
      final success = await completer.future;
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Group and all associated data deleted successfully',
              ),
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Text(message, style: GoogleFonts.beVietnamPro(fontSize: 14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
