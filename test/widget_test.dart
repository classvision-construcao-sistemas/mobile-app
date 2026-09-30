import 'package:flutter_test/flutter_test.dart';

import 'package:class_vision/main.dart';

void main() {
  testWidgets('ClassVision app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ClassVisionApp());

    // Verifica que a tela inicial carrega
    await tester.pumpAndSettle();
  });
}
