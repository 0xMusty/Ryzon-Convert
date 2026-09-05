import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryzon/app/app.dart';

void main() {
  testWidgets('App initializes and renders RyzonApp cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RyzonApp(),
      ),
    );
    expect(find.byType(RyzonApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
