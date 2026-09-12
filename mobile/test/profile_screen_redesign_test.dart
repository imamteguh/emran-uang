import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emran_uang/core/utils/responsive_helper.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_user.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/profile/profile.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/user_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Profile Screen & Features Unit/Widget Tests', () {
    test('AuthUser correctly parses createdAt and serializes to JSON', () {
      final now = DateTime(2026, 1, 15, 10, 30);
      final json = {
        'id': 'user_123',
        'email': 'user@example.com',
        'displayName': 'Budi Santoso',
        'avatarUrl': '🦊',
        'authProvider': 'EMAIL',
        'createdAt': now.toIso8601String(),
      };

      final user = AuthUser.fromJson(json);
      expect(user.id, 'user_123');
      expect(user.email, 'user@example.com');
      expect(user.displayName, 'Budi Santoso');
      expect(user.avatarUrl, '🦊');
      expect(user.authProvider, 'EMAIL');
      expect(user.createdAt, now);

      final outJson = user.toJson();
      expect(outJson['createdAt'], now.toIso8601String());
    });

    test('ProfilePreferences loads defaults and persists updates', () async {
      final initial = await ProfilePreferences.loadPreferences();
      expect(initial['push'], true);
      expect(initial['email'], false);
      expect(initial['monthly'], true);
      expect(initial['theme'], 'Light');
      expect(initial['language'], 'id');

      await ProfilePreferences.saveNotifications(
        push: false,
        email: true,
        monthly: false,
      );
      await ProfilePreferences.saveTheme('Dark');
      await ProfilePreferences.saveLanguage('en');

      final updated = await ProfilePreferences.loadPreferences();
      expect(updated['push'], false);
      expect(updated['email'], true);
      expect(updated['monthly'], false);
      expect(updated['theme'], 'Dark');
      expect(updated['language'], 'en');
    });

    testWidgets('UserAvatar renders fallback initials and emojis without crashing', (tester) async {
      // Test initials
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(displayName: 'Ahmad Dahlan', size: 60),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);

      // Test emoji
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              displayName: 'Test',
              avatarUrl: '🦁',
              size: 60,
            ),
          ),
        ),
      );
      expect(find.text('🦁'), findsOneWidget);
    });

    testWidgets('ProfileHeroCard renders user details and quick financial chips', (tester) async {
      final user = AuthUser(
        id: 'u1',
        email: 'budi@wallet.app',
        displayName: 'Budi Hartono',
        avatarUrl: '💼',
        authProvider: 'EMAIL',
        createdAt: DateTime(2025, 12, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ProfileHeroCard(
                  responsive: ResponsiveHelper(context),
                  user: user,
                  totalCategories: 8,
                  totalWallets: 2,
                  activeWalletName: 'BCA Utama',
                  activeWalletCurrency: 'IDR',
                  onEditProfile: () {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Budi Hartono'), findsOneWidget);
      expect(find.text('budi@wallet.app'), findsOneWidget);
      expect(find.text('Email Terverifikasi'), findsOneWidget);
      expect(find.text('BCA Utama'), findsOneWidget);
      expect(find.text('8 Jenis'), findsOneWidget);
    });

    testWidgets('ProfileGroupCard and ProfileSettingsTile render with Stitch style', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileGroupCard(
              children: [
                ProfileSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profil',
                  subtitle: 'Nama lengkap dan foto',
                  trailingText: 'Aktif',
                  iconColor: Colors.blue,
                  bgIconColor: Colors.blue.withAlpha(25),
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Nama lengkap dan foto'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);

      await tester.tap(find.text('Edit Profil'));
      expect(tapped, true);
    });

    testWidgets('LogoutConfirmationBottomSheet renders title and buttons', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogoutConfirmationBottomSheet(
              onConfirmLogout: () => confirmed = true,
            ),
          ),
        ),
      );

      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);

      await tester.tap(find.text('Ya, Keluar'));
      expect(confirmed, true);
    });

    testWidgets('HelpCenterBottomSheet renders FAQ items and contact button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpCenterBottomSheet(),
          ),
        ),
      );

      expect(find.text('Pusat Bantuan & FAQ'), findsOneWidget);
      expect(find.text('Hubungi Email Dukungan'), findsOneWidget);
    });

    testWidgets('PrivacyPolicyBottomSheet renders privacy sections and acknowledge button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrivacyPolicyBottomSheet(),
          ),
        ),
      );

      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('Saya Memahami'), findsOneWidget);
    });
  });
}
