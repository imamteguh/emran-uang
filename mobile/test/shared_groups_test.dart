import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emran_uang/core/utils/responsive_helper.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/shared_groups/shared_groups.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestable(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Shared Groups Widgets Test Suite', () {
    testWidgets('CreateGroupCard renders modern title and trigger button', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestable(const CreateGroupCard()));

      expect(find.text('Buat Grup Baru'), findsOneWidget);
      expect(
        find.text('Bagi pengeluaran & dompet bersama'),
        findsOneWidget,
      );
      expect(find.text('Buat'), findsOneWidget);
      expect(find.byIcon(Icons.group_add_rounded), findsOneWidget);
    });

    testWidgets('ActiveSharedGroupsList renders empty state cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          Builder(
            builder: (context) {
              return ActiveSharedGroupsList(
                sharedGroups: const [],
                responsive: ResponsiveHelper(context),
                onGroupActionsPressed: (group, role) {},
              );
            },
          ),
        ),
      );

      expect(find.text('Belum Ada Grup Bersama'), findsOneWidget);
      expect(
        find.textContaining('Buat grup di atas dan undang rekan'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    });

    testWidgets('ActiveSharedGroupsList renders group cards with role badge', (
      tester,
    ) async {
      final mockGroups = [
        {
          'group': {
            'id': 'g1',
            'name': 'Rumah Kontrakan',
            'members': [
              {
                'user': {
                  'displayName': 'Ahmad Fauzi',
                  'avatarUrl': null,
                },
              },
              {
                'user': {
                  'displayName': 'Siti Rahma',
                  'avatarUrl': null,
                },
              },
            ],
            'activeBillsCount': 3,
          },
          'myRole': 'OWNER',
        },
        {
          'group': {
            'id': 'g2',
            'name': 'Trip Liburan Bali',
            'members': [
              {
                'user': {
                  'displayName': 'Budi',
                  'avatarUrl': null,
                },
              },
            ],
            'activeBillsCount': 0,
          },
          'myRole': 'MEMBER',
        },
      ];

      dynamic selectedGroup;
      dynamic selectedRole;

      await tester.pumpWidget(
        buildTestable(
          Builder(
            builder: (context) {
              return ActiveSharedGroupsList(
                sharedGroups: mockGroups,
                responsive: ResponsiveHelper(context),
                onGroupActionsPressed: (group, role) {
                  selectedGroup = group;
                  selectedRole = role;
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Grup Bersama Aktif'), findsOneWidget);
      expect(find.text('2 Grup'), findsOneWidget);

      // First group
      expect(find.text('Rumah Kontrakan'), findsOneWidget);
      expect(find.text('Pemilik'), findsOneWidget);
      expect(find.text('2 Anggota'), findsOneWidget);
      expect(find.text('3 Tagihan Aktif'), findsOneWidget);

      // Second group
      expect(find.text('Trip Liburan Bali'), findsOneWidget);
      expect(find.text('Anggota'), findsOneWidget);
      expect(find.text('1 Anggota'), findsOneWidget);
      expect(find.text('0 Tagihan'), findsOneWidget);

      // Tap first group card
      await tester.tap(find.text('Rumah Kontrakan'));
      await tester.pump();
      expect(selectedGroup?['name'], 'Rumah Kontrakan');
      expect(selectedRole, 'OWNER');
    });

    testWidgets('PendingInvitationsList renders invites and triggers actions', (
      tester,
    ) async {
      final mockInvites = [
        {
          'id': 'inv_1',
          'senderId': 'other_user',
          'sender': {'displayName': 'Citra Dewi'},
          'receiverEmail': 'my@email.com',
          'group': {'name': 'Apartemen Senopati'},
        },
        {
          'id': 'inv_2',
          'senderId': 'my_user_id',
          'receiverEmail': 'friend@email.com',
          'group': {'name': 'Usaha Bersama'},
        },
      ];

      String? acceptedId;
      String? rejectedId;

      await tester.pumpWidget(
        buildTestable(
          Builder(
            builder: (context) {
              return PendingInvitationsList(
                pendingInvites: mockInvites,
                currentUserId: 'my_user_id',
                responsive: ResponsiveHelper(context),
                processingInviteId: null,
                onAccept: (id) => acceptedId = id,
                onReject: (id) => rejectedId = id,
              );
            },
          ),
        ),
      );

      expect(find.text('Undangan Tertunda'), findsOneWidget);
      expect(find.text('2 Baru'), findsOneWidget);

      // Received invite
      expect(find.text('Apartemen Senopati'), findsOneWidget);
      expect(find.text('Diundang oleh Citra Dewi'), findsOneWidget);
      expect(find.text('Terima'), findsOneWidget);

      // Sent invite
      expect(find.text('Usaha Bersama'), findsOneWidget);
      expect(find.text('Mengundang: friend@email.com'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);

      // Tap Terima
      await tester.tap(find.text('Terima'));
      await tester.pump();
      expect(acceptedId, 'inv_1');

      // Tap Tolak (Icons.close_rounded on received invite)
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
      expect(rejectedId, 'inv_1');
    });

    testWidgets(
      'GroupActionsBottomSheet displays owner actions and fires onLeave callback',
      (tester) async {
        final mockGroup = {
          'id': 'g1',
          'name': 'Grup Keluarga',
          'members': [
            {'user': {'displayName': 'Ayah'}},
            {'user': {'displayName': 'Ibu'}},
          ],
        };

        bool leavePressed = false;

        await tester.pumpWidget(
          buildTestable(
            GroupActionsBottomSheet(
              group: mockGroup,
              myRole: 'OWNER',
              onLeave: () => leavePressed = true,
              onDelete: () {},
            ),
          ),
        );

        expect(find.text('Grup Keluarga'), findsOneWidget);
        expect(find.text('Pemilik Grup'), findsOneWidget);
        expect(find.text('2 anggota'), findsOneWidget);
        expect(find.text('Keluar dari Grup'), findsOneWidget);
        expect(find.text('Hapus Grup Permanen'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);

        // Tap Keluar
        await tester.tap(find.text('Keluar dari Grup'));
        await tester.pump();
        expect(leavePressed, true);
      },
    );

    testWidgets(
      'GroupActionsBottomSheet fires onDelete callback for owner',
      (tester) async {
        final mockGroup = {
          'id': 'g1',
          'name': 'Grup Keluarga',
          'members': [
            {'user': {'displayName': 'Ayah'}},
          ],
        };

        bool deletePressed = false;

        await tester.pumpWidget(
          buildTestable(
            GroupActionsBottomSheet(
              group: mockGroup,
              myRole: 'OWNER',
              onLeave: () {},
              onDelete: () => deletePressed = true,
            ),
          ),
        );

        // Tap Hapus
        await tester.tap(find.text('Hapus Grup Permanen'));
        await tester.pump();
        expect(deletePressed, true);
      },
    );
  });
}
