import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../user_avatar.dart';

class ExpenseSharedMembersCard extends StatelessWidget {
  final List<dynamic>? members;

  const ExpenseSharedMembersCard({
    super.key,
    required this.members,
  });

  Widget _buildOverlappingAvatars(List<dynamic> memberList) {
    final displayMembers = memberList.take(3).toList();
    final remainingCount = memberList.length - displayMembers.length;

    const double avatarSize = 32.0;
    const double overlapOffset = 20.0;
    double totalWidth = 0.0;
    if (displayMembers.isNotEmpty) {
      totalWidth = (displayMembers.length - 1) * overlapOffset + avatarSize;
      if (remainingCount > 0) {
        totalWidth += overlapOffset;
      }
    }

    return SizedBox(
      height: 32,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * overlapOffset,
              child: UserAvatar(
                avatarUrl: displayMembers[i] is Map
                    ? displayMembers[i]['avatarUrl'] as String?
                    : null,
                displayName: displayMembers[i] is Map
                    ? (displayMembers[i]['displayName'] as String? ?? '')
                    : '',
                size: avatarSize,
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * overlapOffset,
              child: Container(
                width: avatarSize,
                height: avatarSize,
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

  @override
  Widget build(BuildContext context) {
    final hasMembers = members != null && members!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (hasMembers)
                _buildOverlappingAvatars(members!)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withAlpha(25),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.group,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dibagikan ke Grup',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  Text(
                    'Semua anggota dapat melihat transaksi ini',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: AppTheme.darkSlateVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.groups_rounded, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }
}
