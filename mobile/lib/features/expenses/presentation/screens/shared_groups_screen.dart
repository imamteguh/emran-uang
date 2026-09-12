import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/shared_groups/shared_groups.dart';

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
      context.read<DashboardBloc>().add(
        const DashboardFetchSharedGroupsRequested(),
      );
      _isInit = false;
    }
  }

  void _showGroupActions(dynamic group, dynamic myRole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GroupActionsBottomSheet(
        group: group,
        myRole: myRole,
        onLeave: () => _handleLeaveGroup(group),
        onDelete: () => _handleDeleteGroup(group),
      ),
    );
  }

  Future<void> _handleLeaveGroup(dynamic group) async {
    final groupName = group['name'] ?? 'Grup';
    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Keluar dari Grup',
      message:
          'Apakah Anda yakin ingin keluar dari grup "$groupName"? Anda tidak akan lagi memiliki akses ke transaksi dan dompet bersama grup ini.',
      confirmLabel: 'Ya, Keluar',
      isDestructive: true,
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
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Berhasil keluar dari grup bersama'),
                  ),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteGroup(dynamic group) async {
    final groupName = group['name'] ?? 'Grup';
    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Hapus Grup Permanen',
      message:
          'Apakah Anda yakin ingin menghapus grup "$groupName" beserta seluruh data dan dompet bersamanya? Tindakan ini bersifat permanen dan tidak dapat dibatalkan.',
      confirmLabel: 'Ya, Hapus Permanen',
      isDestructive: true,
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
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Grup dan seluruh data terkait berhasil dihapus',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.darkSlate,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isDestructive
                      ? Icons.warning_amber_rounded
                      : Icons.help_outline_rounded,
                  color: isDestructive
                      ? const Color(0xFFDC2626)
                      : AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.darkSlate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive
                            ? const Color(0xFFDC2626)
                            : AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAcceptInvite(String inviteId) async {
    setState(() {
      _processingInviteId = inviteId;
    });
    final completer = Completer<bool>();
    context.read<DashboardBloc>().add(
      DashboardAcceptInviteRequested(inviteId, completer),
    );
    final success = await completer.future;
    if (mounted) {
      setState(() {
        _processingInviteId = null;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Undangan diterima! Dompet bersama kini aktif.'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleRejectInvite(String inviteId) async {
    setState(() {
      _processingInviteId = inviteId;
    });
    final completer = Completer<bool>();
    context.read<DashboardBloc>().add(
      DashboardRejectInviteRequested(inviteId, completer),
    );
    final success = await completer.future;
    if (mounted) {
      setState(() {
        _processingInviteId = null;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Undangan telah ditolak'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
          backgroundColor: const Color(0xFF0F172A), // Top Dark Navy
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: _isActionLoading
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kelola Grup',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: responsive.scaleFont(17),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Dompet bersama & pembagian tagihan',
                      style: GoogleFonts.beVietnamPro(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                        fontSize: responsive.scaleFont(10.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Muat Ulang',
                onPressed: _isActionLoading
                    ? null
                    : () {
                        context.read<DashboardBloc>().add(
                              const DashboardFetchSharedGroupsRequested(),
                            );
                      },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              color: AppTheme.primary,
              backgroundColor: Colors.white,
              onRefresh: () async {
                context.read<DashboardBloc>().add(
                  const DashboardFetchSharedGroupsRequested(),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Info Banner in Dark Navy
                    Container(
                      color: const Color(0xFF0F172A),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha(25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF38BDF8),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Grup memudahkan Anda berbagi catatan pengeluaran secara otomatis melalui Dompet Bersama.',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: const Color(0xFFCBD5E1),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Curved Light Surface
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, -3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Create New Group Card
                          const CreateGroupCard(),
                          const SizedBox(height: 24),

                          // 2. Pending Invitations Section
                          if (provider.pendingInvites.isNotEmpty) ...[
                            PendingInvitationsList(
                              pendingInvites: provider.pendingInvites,
                              currentUserId: currentUser?.id,
                              responsive: responsive,
                              processingInviteId: _processingInviteId,
                              onAccept: _handleAcceptInvite,
                              onReject: _handleRejectInvite,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 3. Active Shared Groups Section
                          ActiveSharedGroupsList(
                            sharedGroups: provider.sharedGroups,
                            responsive: responsive,
                            onGroupActionsPressed: _showGroupActions,
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
        if (_isActionLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memproses...',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
