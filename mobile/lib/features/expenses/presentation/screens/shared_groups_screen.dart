import 'package:emran_uang/features/expenses/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class SharedGroupsScreen extends StatefulWidget {
  const SharedGroupsScreen({super.key});

  @override
  State<SharedGroupsScreen> createState() => _SharedGroupsScreenState();
}

class _SharedGroupsScreenState extends State<SharedGroupsScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).fetchSharedGroups();
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (currentUser?.avatarUrl != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(currentUser!.avatarUrl!),
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryContainer.withAlpha(51),
                child: Text(
                  currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              'WalletShare',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: responsive.scaleFont(20),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: () => provider.fetchSharedGroups(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.fetchSharedGroups();
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
    );
  }

  // ─── Create Group Card ─────────────────────────────────────────────────────

  Widget _buildCreateGroupCard(
    BuildContext context,
    DashboardProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(boxShadow: AppTheme.softShadow),
      child: ClipRRect(
        borderRadius: AppTheme.roundedBorder,
        child: Material(
          color: AppTheme.primaryContainer,
          child: InkWell(
            onTap: () => _showCreateGroupDialog(context, provider),
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

  void _showCreateGroupDialog(
    BuildContext context,
    DashboardProvider provider,
  ) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: Row(
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
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
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
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final success = await provider.sendInvite(
                      emailController.text.trim(),
                      groupName: nameController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Group created and invitation sent!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to create group invitation.'),
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
                child: Text(
                  'Create Group',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Pending Invitations ───────────────────────────────────────────────────

  Widget _buildPendingInvitations(
    BuildContext context,
    DashboardProvider provider,
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            final success = await provider.rejectGroupInvite(
                              invite['id'],
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invitation rejected'),
                                ),
                              );
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
                          onPressed: () async {
                            final success = await provider.acceptGroupInvite(
                              invite['id'],
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invitation accepted! Shared wallet active.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.check,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary.withAlpha(20),
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
    DashboardProvider provider,
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

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      color: stripeColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.darkSlate,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${membersList.length} members • Active',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppTheme.darkSlateVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildOverlappingAvatars(
                                membersList,
                                currentUserId,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MEMBERS LIST',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkSlateVariant,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      membersList
                                          .map(
                                            (m) =>
                                                m['user']?['displayName'] ??
                                                'User',
                                          )
                                          .join(', '),
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.darkSlate,
                                      ),
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'leave') {
                                      final confirm = await _showConfirmDialog(
                                        context,
                                        'Leave Group',
                                        'Are you sure you want to leave this shared group?',
                                      );
                                      if (confirm == true && context.mounted) {
                                        final success = await provider
                                            .leaveGroup(group['id']);
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Left the group successfully',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else if (value == 'archive') {
                                      final confirm = await _showConfirmDialog(
                                        context,
                                        'Archive Group',
                                        'Only the owner can archive this group. Are you sure you want to archive it?',
                                      );
                                      if (confirm == true && context.mounted) {
                                        final success = await provider
                                            .archiveGroup(group['id']);
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Group archived successfully',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'leave',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.exit_to_app,
                                            color: AppTheme.error,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Leave Group'),
                                        ],
                                      ),
                                    ),
                                    if (myRole == 'OWNER')
                                      const PopupMenuItem(
                                        value: 'archive',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.archive_outlined,
                                              color: AppTheme.primary,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Archive Group'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverlappingAvatars(
    List<dynamic> members,
    String? currentUserId,
  ) {
    final displayMembers = members.take(3).toList();
    final remainingCount = members.length - displayMembers.length;

    return SizedBox(
      height: 32,
      width: (displayMembers.length * 20.0) + (remainingCount > 0 ? 24.0 : 0.0),
      child: Stack(
        children: [
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * 20.0,
              child: _buildAvatarCircle(
                displayMembers[i]['user'],
                currentUserId,
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * 20.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryFixed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onTertiaryFixed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(dynamic user, String? currentUserId) {
    if (user == null) return const SizedBox();
    final isMe = user['id'] == currentUserId;
    final name = user['displayName'] ?? '';
    final avatarUrl = user['avatarUrl'];

    if (isMe) {
      return UserAvatar(avatarUrl: avatarUrl, displayName: "ME", size: 32);
    }

    return UserAvatar(avatarUrl: avatarUrl, displayName: name, size: 32);
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
