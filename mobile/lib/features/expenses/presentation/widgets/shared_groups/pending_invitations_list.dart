import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';

class PendingInvitationsList extends StatelessWidget {
  final List<dynamic> pendingInvites;
  final String? currentUserId;
  final ResponsiveHelper responsive;
  final String? processingInviteId;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  const PendingInvitationsList({
    super.key,
    required this.pendingInvites,
    required this.currentUserId,
    required this.responsive,
    required this.processingInviteId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingInvites.isEmpty) return const SizedBox.shrink();

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
                '${pendingInvites.length} New',
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
          itemCount: pendingInvites.length,
          itemBuilder: (context, index) {
            final invite = pendingInvites[index];
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
                    processingInviteId == invite['id']
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
                                onPressed: processingInviteId != null
                                    ? null
                                    : () => onReject(invite['id']),
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
                                onPressed: processingInviteId != null
                                    ? null
                                    : () => onAccept(invite['id']),
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
}
