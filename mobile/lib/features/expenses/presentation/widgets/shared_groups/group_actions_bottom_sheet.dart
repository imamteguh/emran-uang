import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class GroupActionsBottomSheet extends StatelessWidget {
  final dynamic group;
  final dynamic myRole;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  const GroupActionsBottomSheet({
    super.key,
    required this.group,
    required this.myRole,
    required this.onLeave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groupName = group['name'] ?? 'Shared Group';

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
              Navigator.of(context).pop();
              onLeave();
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
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ],
      ),
    );
  }
}
