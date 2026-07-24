import 'package:contacts_exporter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ContactsExporterApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ContactsExporterApp());
    expect(find.text('Contacts Exporter'), findsOneWidget);
  });
}
