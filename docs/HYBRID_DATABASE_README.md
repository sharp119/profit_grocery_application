# ProfitGrocery Hybrid Database Implementation

This repository has been updated to implement a hybrid approach using both Firebase Realtime Database and Cloud Firestore, combining the best features of each database for different parts of the application.

## Implementation Overview

### Added Components

1. **Firestore Models**
   - `UserFirestoreModel` - Firestore version of user model
   - `SessionFirestoreModel` - Firestore version of session model

2. **Firestore Repositories**
   - `AuthRepositoryFirestoreImpl` - Authentication handling with Firestore
   - `UserRepositoryFirestoreImpl` - User data management with Firestore

3. **Services**
   - `SessionManagerFirestore` - Session management using Firestore
   - `UserServiceHybrid` - Service that works with both databases

4. **Factory**
   - `RepositoryFactory` - Creates appropriate implementations based on configuration

5. **Migration Utilities**
   - `DatabaseMigrator` - Migrates data between databases
   - `DataMigrationPage` - Admin UI for controlling migration

6. **Configuration**
   - Remote config parameter `prefer_firestore` controls which implementation to use

7. **Security**
   - Firestore security rules in `firestore.rules`
   - Firestore indexes in `firestore.indexes.json`

8. **Documentation**
   - Detailed explanation in `docs/database/hybrid_database_approach.md`

### Modified Components

1. **Main App**
   - Updated dependency injection in `main.dart`
   - Added Firestore initialization

2. **Home Page**
   - Updated to use `UserServiceHybrid` instead of `UserService`

3. **Dependencies**
   - Added Cloud Firestore (already in pubspec.yaml)

## Usage

The application now automatically detects which database implementation to use based on the Firebase Remote Config parameter `prefer_firestore`:

- If `true`: The app will use Firestore for authentication, user data, and session management
- If `false`: The app will continue using Realtime Database for these features

Data that benefits from real-time synchronization (inventory, active carts, etc.) will continue to use Realtime Database regardless of this setting.

## Migration

To migrate data from Realtime Database to Firestore:

1. Access the admin section of the app
2. Navigate to the Data Migration page
3. Click "Start Migration"
4. The tool will copy data from RTDB to Firestore without overwriting existing data

## Benefits of Hybrid Approach

- **Authentication & User Data**: Stored in Firestore for better query capabilities and security
- **Inventory & Real-time Features**: Remain in Realtime Database for faster synchronization
- **Flexibility**: Toggle between implementations without app updates
- **Cost Optimization**: Each database is used for what it does best
- **Progressive Migration**: No need to migrate everything at once

## Security

The hybrid approach includes security rules for both databases:

- Firestore rules use document-level security with more complex conditions
- Realtime Database rules continue to provide basic path-based security

## Future Directions

The hybrid approach allows for:

1. Gradual migration to Firestore if desired
2. Continued use of Realtime Database for high-frequency updates
3. Flexibility to choose the best database for each feature
4. Ability to switch back if needed during testing

## Folder Structure

```
lib/
├── data/
│   ├── models/
│   │   ├── firestore/
│   │   │   ├── session_firestore_model.dart
│   │   │   └── user_firestore_model.dart
│   │   └── ...
│   ├── repositories/
│   │   ├── firestore/
│   │   │   ├── auth_repository_firestore_impl.dart
│   │   │   └── user_repository_firestore_impl.dart
│   │   └── ...
│   └── ...
├── services/
│   ├── session_manager.dart (Realtime DB)
│   ├── session_manager_firestore.dart
│   ├── service_factory.dart
│   ├── user_service.dart (Realtime DB)
│   ├── user_service_hybrid.dart
│   └── ...
├── utils/
│   ├── migration/
│   │   └── database_migrator.dart
│   └── ...
└── ...
```