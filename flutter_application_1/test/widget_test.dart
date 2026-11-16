import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/di/injection.dart';

void main() {
  testWidgets('store app displays its home screen', (WidgetTester tester) async {
    await configureDependencies();

    await tester.pumpWidget(const ECommerceApp());

    expect(find.text('NOVA Store'), findsOneWidget);
  });
}
