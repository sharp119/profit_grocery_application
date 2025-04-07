import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:profit_grocery_application/core/errors/failures.dart';
import 'package:profit_grocery_application/domain/repositories/auth_repository.dart';
import 'package:profit_grocery_application/domain/repositories/user_repository.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_event.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_state.dart';
import 'package:profit_grocery_application/presentation/blocs/user/user_bloc.dart';
import 'package:profit_grocery_application/presentation/pages/authentication/phone_entry_page.dart';
import 'package:profit_grocery_application/presentation/pages/authentication/otp_verification_page.dart';

@GenerateMocks([AuthRepository, UserRepository])
class MockAuthRepository extends Mock implements AuthRepository {}
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('Authentication Flow Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late AuthBloc authBloc;
    late UserBloc userBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
      userBloc = UserBloc(userRepository: mockUserRepository);
    });

    tearDown(() {
      authBloc.close();
      userBloc.close();
    });

    group('PhoneEntryPage', () {
      testWidgets('should validate phone number format', (WidgetTester tester) async {
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

      testWidgets('should show loading indicator when sending OTP', (WidgetTester tester) async {
        // Setup mock behavior
        when(mockAuthRepository.sendOTP(any))
            .thenAnswer((_) async => Future.delayed(
                  const Duration(seconds: 1),
                  () => const Right('mock_request_id'),
                ));

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

        // Enter a valid phone number
        await tester.enterText(phoneField, '9876543210');
        await tester.tap(continueButton);
        await tester.pump();

        // Loading indicator should appear
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle OTP sending failure', (WidgetTester tester) async {
        // Setup mock behavior
        when(mockAuthRepository.sendOTP(any))
            .thenAnswer((_) async => Left(ServerFailure(message: 'Failed to send OTP')));

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

        // Enter a valid phone number
        await tester.enterText(phoneField, '9876543210');
        await tester.tap(continueButton);
        
        // Wait for the error to be processed
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Error snackbar should appear
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Failed to send OTP'), findsOneWidget);
      });
    });

    group('OtpVerificationPage', () {
      testWidgets('should auto-verify OTP when complete', (WidgetTester tester) async {
        // Setup mock behavior
        when(mockAuthRepository.verifyOTP(
          requestId: anyNamed('requestId'),
          otp: anyNamed('otp'),
          phoneNumber: anyNamed('phoneNumber'),
        )).thenAnswer((_) async => const Right('mock_token'));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: authBloc,
              child: OtpVerificationPage(
                phoneNumber: '9876543210',
                requestId: 'mock_request_id',
              ),
            ),
          ),
        );

        // Find the OTP input field
        final otpField = find.byType(Pinput);

        // Enter a complete OTP
        await tester.enterText(otpField.first, '1234');
        await tester.pump();
        
        // Wait for auto-verification
        await tester.pump(const Duration(milliseconds: 300));

        // Verify that OTP verification was called
        verify(mockAuthRepository.verifyOTP(
          requestId: 'mock_request_id',
          otp: '1234',
          phoneNumber: '9876543210',
        )).called(1);
      });

      testWidgets('should handle OTP verification error', (WidgetTester tester) async {
        // Setup mock behavior
        when(mockAuthRepository.verifyOTP(
          requestId: anyNamed('requestId'),
          otp: anyNamed('otp'),
          phoneNumber: anyNamed('phoneNumber'),
        )).thenAnswer((_) async => Left(OtpInvalidFailure()));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: authBloc,
              child: OtpVerificationPage(
                phoneNumber: '9876543210',
                requestId: 'mock_request_id',
              ),
            ),
          ),
        );

        // Find the OTP input field
        final otpField = find.byType(Pinput);
        final verifyButton = find.text('Verify & Continue');

        // Enter a complete OTP
        await tester.enterText(otpField.first, '1234');
        await tester.tap(verifyButton);
        
        // Wait for verification attempt
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Error snackbar should appear
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Invalid OTP code. Please check and try again.'), findsOneWidget);
      });
    });

    group('AuthBloc', () {
      test('initial state should be unauthenticated', () {
        expect(authBloc.state.status, equals(AuthStatus.initial));
      });

      test('emits loading and OtpSent states when SendOtpEvent succeeds', () async {
        // Setup mock
        when(mockAuthRepository.sendOTP(any)).thenAnswer((_) async => const Right('mock_request_id'));

        // Expectations
        final expected = [
          isA<AuthState>().having((state) => state.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((state) => state.status, 'status', AuthStatus.otpSent)
              .having((state) => state.requestId, 'requestId', 'mock_request_id')
              .having((state) => state.phoneNumber, 'phoneNumber', '9876543210'),
        ];

        // Add event
        authBloc.add(const SendOtpEvent('9876543210'));

        // Verify
        expectLater(authBloc.stream, emitsInOrder(expected));
      });

      test('emits loading and error states when SendOtpEvent fails', () async {
        // Setup mock
        when(mockAuthRepository.sendOTP(any))
            .thenAnswer((_) async => Left(PhoneNumberInvalidFailure()));

        // Expectations
        final expected = [
          isA<AuthState>().having((state) => state.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((state) => state.status, 'status', AuthStatus.error)
              .having((state) => state.errorMessage, 'errorMessage', 
                  'Invalid phone number format. Please enter a valid 10-digit number.'),
        ];

        // Add event
        authBloc.add(const SendOtpEvent('12345'));

        // Verify
        expectLater(authBloc.stream, emitsInOrder(expected));
      });

      test('emits loading and authenticated states when VerifyOtpEvent succeeds', () async {
        // Setup mock
        when(mockAuthRepository.verifyOTP(
          requestId: anyNamed('requestId'),
          otp: anyNamed('otp'),
          phoneNumber: anyNamed('phoneNumber'),
        )).thenAnswer((_) async => const Right('mock_token'));

        when(mockAuthRepository.getCurrentUserId())
            .thenAnswer((_) async => 'mock_user_id');

        // Expectations
        final expected = [
          isA<AuthState>().having((state) => state.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((state) => state.status, 'status', AuthStatus.authenticated)
              .having((state) => state.userId, 'userId', 'mock_user_id'),
        ];

        // Add event
        authBloc.add(const VerifyOtpEvent(
          requestId: 'mock_request_id',
          otp: '1234',
          phoneNumber: '9876543210',
        ));

        // Verify
        expectLater(authBloc.stream, emitsInOrder(expected));
      });

      test('emits loading and error states when VerifyOtpEvent fails', () async {
        // Setup mock
        when(mockAuthRepository.verifyOTP(
          requestId: anyNamed('requestId'),
          otp: anyNamed('otp'),
          phoneNumber: anyNamed('phoneNumber'),
        )).thenAnswer((_) async => Left(OtpInvalidFailure()));

        // Expectations
        final expected = [
          isA<AuthState>().having((state) => state.status, 'status', AuthStatus.loading),
          isA<AuthState>()
              .having((state) => state.status, 'status', AuthStatus.error)
              .having((state) => state.errorMessage, 'errorMessage', 
                  'Invalid OTP code. Please check and try again.'),
        ];

        // Add event
        authBloc.add(const VerifyOtpEvent(
          requestId: 'mock_request_id',
          otp: '1234',
          phoneNumber: '9876543210',
        ));

        // Verify
        expectLater(authBloc.stream, emitsInOrder(expected));
      });

      test('emits loading and unauthenticated states when LogoutEvent is added', () async {
        // Setup
        when(mockAuthRepository.logout()).thenAnswer((_) async => null);

        // Expectations
        final expected = [
          isA<AuthState>().having((state) => state.status, 'status', AuthStatus.loading),
          isA<AuthState>().having((state) => state.status, 'status', AuthStatus.unauthenticated),
        ];

        // Add event
        authBloc.add(const LogoutEvent());

        // Verify
        expectLater(authBloc.stream, emitsInOrder(expected));
      });
    });

    group('Session Management', () {
      test('should verify session on isLoggedIn check', () async {
        // Setup
        when(mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);

        // Action
        final result = await mockAuthRepository.isLoggedIn();

        // Verify
        expect(result, true);
        verify(mockAuthRepository.isLoggedIn()).called(1);
      });
    });
  });
}