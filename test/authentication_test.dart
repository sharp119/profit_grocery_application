import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pinput/pinput.dart';
import 'package:profit_grocery_application/core/errors/failures.dart';
import 'package:profit_grocery_application/domain/entities/user.dart';
import 'package:profit_grocery_application/domain/repositories/auth_repository.dart';
import 'package:profit_grocery_application/domain/repositories/user_repository.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_event.dart';
import 'package:profit_grocery_application/presentation/blocs/auth/auth_state.dart';
import 'package:profit_grocery_application/presentation/blocs/user/user_bloc.dart';
import 'package:profit_grocery_application/presentation/pages/authentication/phone_entry_page.dart';
import 'package:profit_grocery_application/presentation/pages/authentication/otp_verification_page.dart';

// Define mock classes manually instead of using @GenerateMocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockUserBloc extends Mock implements UserBloc {}

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

    group('PhoneEntryPage',