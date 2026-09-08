import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/screens/ocr_scan_screen.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_bloc.dart';
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
}
