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
          const SnackBar(
            content: Text('Invitation accepted! Shared wallet active.'),
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
          const SnackBar(content: Text('Invitation rejected')),
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
                context.read<DashboardBloc>().add(
                  const DashboardFetchSharedGroupsRequested(),
                );
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
}
