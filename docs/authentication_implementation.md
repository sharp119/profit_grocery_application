# ProfitGrocery Authentication Implementation

This document provides an overview of the authentication system implemented in the ProfitGrocery application. The system uses a phone number + OTP based authentication flow with custom session management.

## 1. Authentication Flow

### 1.1 For New Users:
1. User enters phone number on PhoneEntryPage
2. System checks if the phone number exists in the database
3. If not found, the system identifies this as a new user flow
4. OTP is sent to the provided phone number
5. User enters OTP on OtpVerificationPage
6. After successful OTP verification, user is redirected to UserRegistrationPage
7. User provides basic profile information (name, email)
8. User profile is created and session is established
9. User is redirected to HomePage

### 1.2 For Existing Users:
1. User enters phone number on PhoneEntryPage
2. System identifies the phone number as belonging to an existing user
3. OTP is sent to the provided phone number
4. User enters OTP on OtpVerificationPage
5. After successful OTP verification, session is established
6. User is directly redirected to HomePage (skipping registration)

## 2. Key Components

### 2.1 Backend Components:
- **AuthRepository**: Interface defining authentication operations
- **AuthRepositoryImpl**: Implementation of authentication operations
- **OTPService**: Handles OTP sending and verification
- **SessionManager**: Manages user sessions with secure token generation
- **UserService**: Provides access to current user data throughout the app

### 2.2 Frontend Components:
- **PhoneEntryPage**: UI for entering phone number
- **OtpVerificationPage**: UI for entering and verifying OTP
- **UserRegistrationPage**: UI for completing user profile
- **AuthBloc**: Manages authentication state and logic
- **UserBloc**: Manages user profile state and logic

### 2.3 Data Flow Components:
- **SharedPreferences**: For persisting session data on the device
- **Firebase Realtime Database**: For storing user data and session information
- **FirebaseRemoteConfig**: For configuration parameters

## 3. Error Handling

The authentication system implements comprehensive error handling with specific error types:

- **PhoneNumberInvalidFailure**: When phone number format is invalid
- **OtpInvalidFailure**: When OTP verification fails due to incorrect code
- **OtpExpiredFailure**: When OTP code has expired
- **TooManyRequestsFailure**: When rate limits are exceeded
- **SessionExpiredFailure**: When user session expires
- **UserNotFoundFailure**: When user data cannot be retrieved
- **ServerFailure**: For general server-side errors
- **NetworkFailure**: For network connection issues

Each error type comes with user-friendly messages and appropriate UI feedback.

## 4. Security Measures

### 4.1 OTP Security
- 4-digit OTP codes
- Limited validity period
- Rate-limiting to prevent brute force attempts
- Server-side verification

### 4.2 Session Security
- Secure token generation using cryptographic methods
- Token expiration mechanism
- Server-side session validation
- Cross-device logout capability
- Protection against session hijacking

### 4.3 User Data Protection
- Phone numbers partially masked in logs
- Sensitive data not stored in plain text
- Access control based on authentication status

## 5. User Experience Enhancements

- Visual differentiation between login and registration flows
- Auto-verification of OTP when all digits are entered
- Resend OTP capability with countdown timer
- Session persistence for seamless app relaunch
- Graceful error handling with user-friendly messages
- Loading indicators for async operations

## 6. Testing

The authentication system includes comprehensive tests:
- Unit tests for BLoCs and repositories
- Integration tests for authentication flows
- Mock testing for external dependencies
- Error case testing

## 7. Maintenance and Future Improvements

- Implement biometric authentication for returning users
- Add social authentication options
- Enhance session security with device fingerprinting
- Implement 2-factor authentication for high-value transactions
- Add account recovery mechanisms