import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/screens/ocr_scan_screen.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_bloc.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/ocr/ocr_result_preview.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/ocr/ocr_bottom_action_bar.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/ocr/ocr_scan_cubit.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/ocr/ocr_scan_state.dart';
import 'package:emran_uang/core/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_URL=https://wallet.libertysky.icu/api\n');
  });

  testWidgets('Test semantics on OcrScanScreen', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => DashboardBloc(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OcrScanScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    handle.dispose();
  });

  testWidgets('Test semantics on OcrResultPreview and BottomBar', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: OcrResultPreview(
              amount: 199399,
              description: 'Belanja di Tokopedia',
              category: ExpenseCategory(
                id: 'cat_1',
                name: 'Shopping',
                icon: 'shopping_bag',
                color: '#4F46E5',
              ),
              rawSuggestion: 'Shopping',
              date: DateTime.parse('2026-07-02T00:00:00'),
              currencyCode: 'IDR',
              currencySymbol: 'Rp',
              availableCategories: [
                ExpenseCategory(
                  id: 'cat_1',
                  name: 'Shopping',
                  icon: 'shopping_bag',
                  color: '#4F46E5',
                ),
              ],
              onCategoryChanged: (_) {},
            ),
          ),
          bottomNavigationBar: OcrBottomActionBar(
            onRetake: () {},
            onConfirm: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('Test OcrScanScreen in Success State', (tester) async {
    final cubit = OcrScanCubit();
    cubit.emit(OcrScanState(
      status: OcrScanStatus.success,
      amount: 199399,
      description: 'Belanja di Tokopedia',
      date: DateTime.parse('2026-07-02T00:00:00'),
      category: ExpenseCategory(
        id: 'cat_1',
        name: 'Shopping',
        icon: 'shopping_bag',
        color: '#4F46E5',
      ),
    ));

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => DashboardBloc(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: OcrScanScreen(cubit: cubit),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final bottomBarSize = tester.getSize(find.byType(OcrBottomActionBar));
    expect(bottomBarSize.height, lessThan(100.0));

    expect(find.text('Belanja di Tokopedia'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Use This Data'), findsOneWidget);
  });
}

