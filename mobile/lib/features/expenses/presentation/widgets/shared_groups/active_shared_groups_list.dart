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
    const double avatarSize = 28.0;
    const double spacing = 18.0;

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
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _buildAvatarCircle(
                  displayMembers[i]['user'],
                  avatarSize - 4,
                ),
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * spacing,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF475569),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDBEAFE),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.groups_rounded,
                color: AppTheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Grup Bersama',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Buat grup di atas dan undang rekan untuk mulai mencatat dan membagi pengeluaran bersama secara transparan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                color: const Color(0xFF64748B),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.diversity_3_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Grup Bersama Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(17),
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkSlate,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${sharedGroups.length} Grup',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
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
            final groupName = group['name'] ?? 'Grup Bersama';
            final membersList = group['members'] as List? ?? [];
            final activeBillsCount = group['activeBillsCount'] ?? 0;
            final isOwner = myRole == 'OWNER';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: AppTheme.softShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onGroupActionsPressed(group, myRole),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // Top Section: Group Logo + Title + Role + Action Icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0F172A),
                                    Color(0xFF004BC6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                groupName.isNotEmpty
                                    ? groupName[0].toUpperCase()
                                    : 'G',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppTheme.darkSlate,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOwner
                                              ? const Color(0xFFE0E7FF)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isOwner
                                                  ? Icons.star_rounded
                                                  : Icons.person_outline_rounded,
                                              size: 12,
                                              color: isOwner
                                                  ? const Color(0xFF4338CA)
                                                  : const Color(0xFF475569),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOwner ? 'Pemilik' : 'Anggota',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: isOwner
                                                  ? const Color(0xFF4338CA)
                                                  : const Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF64748B),
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () =>
                                  onGroupActionsPressed(group, myRole),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),

                        // Bottom Section: Member Avatars & Bills Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildOverlappingAvatars(membersList),
                                const SizedBox(width: 10),
                                Text(
                                  '${membersList.length} Anggota',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: activeBillsCount > 0
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: activeBillsCount > 0
                                      ? const Color(0xFFDBEAFE)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 13,
                                    color: activeBillsCount > 0
                                        ? AppTheme.primary
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    activeBillsCount > 0
                                        ? '$activeBillsCount Tagihan Aktif'
                                        : '0 Tagihan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: activeBillsCount > 0
                                          ? AppTheme.primary
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
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
}
