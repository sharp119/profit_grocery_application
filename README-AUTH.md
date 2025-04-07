# ProfitGrocery Authentication System

This document describes the custom phone-based OTP authentication system implemented for the ProfitGrocery application.

## Overview

The authentication system implements a secure, phone-based OTP verification flow that:

1. Checks if a user exists before sending an OTP
2. Handles both new user registration and existing user login
3. Securely manages sessions across devices
4. Tracks user login status in Firebase Realtime Database

## Implementation Details

### Key Components

1. **AuthRepositoryImpl**
   - Enhanced with user existence checking
   - Separate flows for new and existing users
   - Integration with SessionManager

2. **SessionManager**
   - Secure token generation and validation
   - Session tracking in both SharedPreferences and Firebase
   - Session timeout and automatic invalidation

3. **OTPService**
   - Integration with MSG91 for OTP delivery and verification
   - Token verification capabilities

### Authentication Flow

1. **Phone Number Entry**
   - User enters their phone number
   - System checks if this user already exists
   - OTP is sent to the provided number
   - Flow is marked as either login or registration

2. **OTP Verification**
   - User enters the OTP code
   - System verifies the code with MSG91
   - A secure session is created if verification succeeds
   - User ID is retrieved (for existing users) or created (for new users)

3. **Session Management**
   - Each login creates a new secure session
   - Sessions have configurable timeout (default: 60 minutes)
   - Sessions are tracked both locally and in Firebase
   - Multiple device logins are supported

## Firebase Schema

The authentication system uses the following Firebase Realtime Database structure:

```
/users/{userId}
  - phoneNumber: string
  - name: string (optional)
  - email: string (optional)
  - addresses: array (optional)
  - createdAt: timestamp
  - lastLogin: timestamp
  - isOptedInForMarketing: boolean

/sessions/{userId}
  - token: string
  - createdAt: timestamp
  - expiresAt: timestamp
  - lastActive: timestamp
  - deviceInfo: object
```

## Testing the Authentication Flow

To test the authentication flow:

1. Enter an existing phone number to test the login flow
2. Enter a new phone number to test the registration flow
3. Verify OTP handling by checking console logs (in debug mode)
4. Monitor session creation in Firebase

## Future Enhancements

1. Implement biometric authentication for returning users
2. Add multi-factor authentication options
3. Improve device fingerprinting for better security
4. Add admin capabilities to manage and monitor user sessions
