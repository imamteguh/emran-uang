import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/screens/expense_entry_screen.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/expense_entry/expense_amount_card.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/expense_entry/expense_category_selector.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/expense_entry/expense_date_selector.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/expense_entry/expense_note_field.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/expense_entry/expense_routine_toggle.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/expense_entry/expense_save_button.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_URL=https://dummy.api\n');
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id', null);
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Expense Entry UI/UX Redesign Indonesian Localization Tests', () {
    testWidgets('ExpenseAmountCard displays Indonesian labels, presets and handles additions',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrapWithMaterial(
          ExpenseAmountCard(
            controller: controller,
            currencyCode: 'IDR',
            currencySymbol: 'Rp',
          ),
        ),
      );

      // Verify Indonesian label
      expect(find.text('NOMINAL PENGELUARAN'), findsOneWidget);
      expect(find.text('+10rb'), findsOneWidget);
      expect(find.text('+20rb'), findsOneWidget);
      expect(find.text('+50rb'), findsOneWidget);
      expect(find.text('+100rb'), findsOneWidget);

      // Tap +50rb preset chip
      await tester.tap(find.text('+50rb'));
      await tester.pumpAndSettle();

      expect(controller.text, contains('50'));

      // Tap +20rb preset chip
      await tester.tap(find.text('+20rb'));
      await tester.pumpAndSettle();

      expect(controller.text, contains('70'));

      // Reset button appears and functions
      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(controller.text, '');
    });

    testWidgets('ExpenseCategorySelector displays Indonesian labels and categories',
        (tester) async {
      final dummyCategories = [
        ExpenseCategory(id: 'c1', name: 'Makanan', icon: 'restaurant', color: '#FF5722'),
        ExpenseCategory(id: 'c2', name: 'Transportasi', icon: 'directions_car', color: '#2196F3'),
        ExpenseCategory(id: 'c3', name: 'Other', icon: 'more_horiz', color: '#9E9E9E'),
      ];

      ExpenseCategory? selected;

      await tester.pumpWidget(
        wrapWithMaterial(
          ExpenseCategorySelector(
            categories: dummyCategories,
            selectedCategory: dummyCategories[0],
            onCategorySelected: (cat) => selected = cat,
          ),
        ),
      );

      expect(find.text('KATEGORI PENGELUARAN'), findsOneWidget);
      expect(find.text('Kelola'), findsOneWidget);
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('Transportasi'), findsOneWidget);
      // 'Other' rendered as 'Lainnya'
      expect(find.text('Lainnya'), findsOneWidget);

      // Tap second category
      await tester.tap(find.text('Transportasi'));
      await tester.pumpAndSettle();
      expect(selected?.id, 'c2');
    });

    testWidgets('ExpenseDateSelector displays Indonesian date chips and active time card',
        (tester) async {
      final date = DateTime(2026, 9, 11, 14, 30);

      await tester.pumpWidget(
        wrapWithMaterial(
          ExpenseDateSelector(
            selectedDate: date,
            onDateChanged: (_) {},
            onTimeChanged: (_, {targetDate}) {},
          ),
        ),
      );

      expect(find.text('WAKTU & TANGGAL TRANSAKSI'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.text('Ubah Waktu'), findsOneWidget);
      expect(find.text('WIB'), findsOneWidget);
    });

    testWidgets('ExpenseNoteField displays Indonesian label and placeholder',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrapWithMaterial(
          ExpenseNoteField(
            controller: controller,
          ),
        ),
      );

      expect(find.text('CATATAN TRANSAKSI'), findsOneWidget);
      expect(find.text('Opsional'), findsOneWidget);
      expect(
        find.text('Catatan pengeluaran (misal: Makan siang kantor, belanja bulanan...)'),
        findsOneWidget,
      );
    });

    testWidgets('ExpenseRoutineToggle displays Indonesian recurring labels',
        (tester) async {
      bool isRoutine = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          StatefulBuilder(
            builder: (context, setState) => ExpenseRoutineToggle(
              isRoutine: isRoutine,
              onChanged: (val) => setState(() => isRoutine = val),
            ),
          ),
        ),
      );

      expect(find.text('Pengeluaran Rutin'), findsOneWidget);
      expect(
        find.text('Tandai sebagai pengeluaran berulang bulanan'),
        findsOneWidget,
      );
    });

    testWidgets('ExpenseSaveButton displays Indonesian action text and loading state',
        (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ExpenseSaveButton(
            isSaving: false,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Simpan Pengeluaran'), findsOneWidget);

      await tester.pumpWidget(
        wrapWithMaterial(
          ExpenseSaveButton(
            isSaving: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Menyimpan...'), findsOneWidget);
    });

    testWidgets('ExpenseEntryScreen renders all form fields and sticky save button without obscuring body',
        (tester) async {
      final dummyWallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Pribadi',
        type: WalletType.personal,
        currency: 'IDR',
      );
      final dummyCat = ExpenseCategory(
        id: 'c1',
        name: 'Makanan',
        icon: 'restaurant',
        color: '#FF5722',
      );

      final dashboardBloc = DashboardBloc();
      dashboardBloc.emit(dashboardBloc.state.copyWith(
        isInitialLoad: false,
        personalWallets: [dummyWallet],
        selectedWallet: dummyWallet,
        categories: [dummyCat],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DashboardBloc>.value(
            value: dashboardBloc,
            child: const ExpenseEntryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify all components in the body are rendered and visible!
      expect(find.text('Catat Pengeluaran'), findsOneWidget);
      expect(find.text('NOMINAL PENGELUARAN'), findsOneWidget);
      expect(find.text('KATEGORI PENGELUARAN'), findsOneWidget);
      expect(find.text('WAKTU & TANGGAL TRANSAKSI'), findsOneWidget);
      expect(find.text('CATATAN TRANSAKSI'), findsOneWidget);
      expect(find.text('Pengeluaran Rutin'), findsOneWidget);
      expect(find.text('Simpan Pengeluaran'), findsOneWidget);
    });

    testWidgets('ExpenseDateSelector opens showDatePicker dialog without crashing and updates date',
        (tester) async {
      DateTime selectedDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ExpenseDateSelector(
                  selectedDate: selectedDate,
                  onDateChanged: (newDate) {
                    setState(() {
                      selectedDate = newDate;
                    });
                  },
                  onTimeChanged: (_, {targetDate}) {},
                );
              },
            ),
          ),
        ),
      );

      // Tap 'Pilih Tanggal' (since selectedDate is today, label is 'Pilih Tanggal')
      expect(find.text('Pilih Tanggal'), findsOneWidget);
      await tester.tap(find.text('Pilih Tanggal'));
      await tester.pumpAndSettle();

      // Verify the date picker dialog is displayed without throwing locale error
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Tap 'OK' button in DatePickerDialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed cleanly
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('ExpenseDateSelector Kemarin chip updates date without opening dialog',
        (tester) async {
      DateTime selectedDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ExpenseDateSelector(
                  selectedDate: selectedDate,
                  onDateChanged: (newDate) {
                    setState(() {
                      selectedDate = newDate;
                    });
                  },
                  onTimeChanged: (_, {targetDate}) {},
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Kemarin'));
      await tester.pumpAndSettle();

      // No dialog should have popped up
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(selectedDate.day, DateTime.now().subtract(const Duration(days: 1)).day);
    });

    testWidgets('ExpenseDateSelector Ubah Waktu opens showTimePicker dialog without non-normalized BoxConstraints crash',
        (tester) async {
      DateTime selectedDate = DateTime(2026, 9, 11, 14, 30);
      TimeOfDay? updatedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ExpenseDateSelector(
                  selectedDate: selectedDate,
                  onDateChanged: (_) {},
                  onTimeChanged: (newTime, {targetDate}) {
                    setState(() {
                      updatedTime = newTime;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap 'Ubah Waktu'
      expect(find.text('Ubah Waktu'), findsOneWidget);
      await tester.tap(find.text('Ubah Waktu'));
      await tester.pumpAndSettle();

      // Verify TimePickerDialog is shown without any crash
      expect(find.byType(TimePickerDialog), findsOneWidget);
      // Verify keyboard mode icon button is omitted (dialOnly mode)
      expect(find.byIcon(Icons.keyboard_outlined), findsNothing);

      // Tap 'OK' in TimePickerDialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed cleanly
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(updatedTime, isNotNull);
    });
  });
}
