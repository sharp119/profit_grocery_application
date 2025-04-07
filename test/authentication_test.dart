import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:profit_grocery_application/domain/repositories/auth_repository.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_event.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_state.dart';
import 'package:profit_grocery_application/presentation/pages/authentication/phone_entry_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Authentication Flow Test', () {
    late MockAuthRepository mockAuthRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('PhoneEntryPage should validate phone number', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: authBloc,
            child: const PhoneEntryPage(),
          ),
        ),
      );

      // Find the form fields and buttons
      final phoneField = find.byType(TextFormField);
      final continueButton = find.byType(ElevatedButton);

      // Enter an invalid phone number (less than 10 digits)
      await tester.enterText(phoneField, '12345');
      await tester.tap(continueButton);
      await tester.pump();

      // Validation error should appear
      expect(find.text('Please enter a valid 10-digit phone number'), findsOneWidget);
    });
  });
}
