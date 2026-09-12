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
            Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Undangan Tertunda',
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFDE68A),
                  width: 1,
                ),
              ),
              child: Text(
                '${pendingInvites.length} Baru',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB45309),
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
            final senderName = invite['sender']?['displayName'] ?? 'Seseorang';
            final isSentByMe = invite['senderId'] == currentUserId;
            final groupName = invite['group']?['name'] ?? 'Grup Bersama';
            final isProcessing = processingInviteId == invite['id'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softShadow,
                border: Border.all(
                  color: isSentByMe
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFBFDBFE),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSentByMe
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isSentByMe
                          ? Icons.outgoing_mail
                          : Icons.mark_email_unread_rounded,
                      color: isSentByMe
                          ? const Color(0xFF64748B)
                          : AppTheme.primary,
                      size: 22,
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
                            fontSize: 15,
                            color: AppTheme.darkSlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isSentByMe
                              ? 'Mengundang: ${invite['receiverEmail']}'
                              : 'Diundang oleh $senderName',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isSentByMe)
                    isProcessing
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Reject Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => onReject(invite['id']),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Accept Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => onAccept(invite['id']),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Terima',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Menunggu',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
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
