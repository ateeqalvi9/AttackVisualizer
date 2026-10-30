import 'package:flutter_test/flutter_test.dart';
import 'package:scientific_cas/main.dart';

void main() {
  testWidgets('App launches and renders navigation and calculator', (WidgetTester tester) async {
    await tester.pumpWidget(const ScientificCasApp());
    await tester.pumpAndSettle();

    // Verify main app title and navigation items
    expect(find.text('Scientific CAS'), findsOneWidget);
    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('2D Plotter'), findsOneWidget);
    expect(find.text('3D Surface'), findsOneWidget);
    expect(find.text('Matrix Lab'), findsOneWidget);
    expect(find.text('CAS Solver'), findsOneWidget);
  });
}
