import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../user_avatar.dart';

class ActiveSharedGroupsList extends StatelessWidget {
  final List<dynamic> sharedGroups;
  final ResponsiveHelper responsive;
  final void Function(dynamic group, dynamic myRole) onGroupActionsPressed;

  const ActiveSharedGroupsList({
    super.key,
    required this.sharedGroups,
    required this.responsive,
    required this.onGroupActionsPressed,
  });

  Widget _buildOverlappingAvatars(List<dynamic> members) {
    final displayMembers = members.take(3).toList();
    final remainingCount = members.length - displayMembers.length;
    const double avatarSize = 32.0;
    const double spacing = 20.0;

    return SizedBox(
      height: avatarSize,
      width: displayMembers.isEmpty
          ? 0.0
          : (remainingCount > 0
              ? (displayMembers.length * spacing) + avatarSize
              : ((displayMembers.length - 1) * spacing) + avatarSize),
      child: Stack(
        children: [
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * spacing,
              child: _buildAvatarCircle(displayMembers[i]['user'], avatarSize),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * spacing,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
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

  @override
  Widget build(BuildContext context) {
    if (sharedGroups.isEmpty) {
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
          itemCount: sharedGroups.length,
          itemBuilder: (context, index) {
            final groupItem = sharedGroups[index];
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
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: stripeColor.withAlpha(51),
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
                              onPressed: () =>
                                  onGroupActionsPressed(group, myRole),
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
}
