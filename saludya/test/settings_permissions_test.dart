import 'package:flutter_test/flutter_test.dart';
import 'package:saludya/features/main/main_page.dart';

void main() {
  test('admission staff and super admins can edit global settings', () {
    expect(canEditGlobalSettings('ADMISSION_STAFF'), isTrue);
    expect(canEditGlobalSettings('SUPER_ADMIN'), isTrue);
    expect(canEditGlobalSettings('PATIENT'), isFalse);
  });
}
