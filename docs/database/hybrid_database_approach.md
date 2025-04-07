# ProfitGrocery Hybrid Database Approach

This document explains the hybrid approach we're using for database interactions in the ProfitGrocery application, combining Firebase Realtime Database and Cloud Firestore.

## 1. Overview

The ProfitGrocery app implements a hybrid database approach:

- **Cloud Firestore**: Used for structured data with infrequent changes
  - User profiles
  - Authentication data
  - Order history
  - Product catalog (base information)

- **Firebase Realtime Database**: Used for real-time data with frequent changes
  - Inventory status
  - Shopping carts
  - Banners and promotions
  - Active sessions (fallback)

This approach leverages the strengths of both databases while minimizing their weaknesses.

## 2. Architecture Components

The hybrid approach consists of the following components:

### 2.1 Models
- `UserModel` - Standard model for Realtime Database
- `UserFirestoreModel` - Firestore-specific implementation
- `SessionFirestoreModel` - Firestore implementation of session tracking

### 2.2 Repositories
- `AuthRepositoryImpl` - Realtime Database implementation 
- `AuthRepositoryFirestoreImpl` - Firestore implementation
- `UserRepositoryImpl` - Realtime Database implementation
- `UserRepositoryFirestoreImpl` - Firestore implementation

### 2.3 Services
- `SessionManager` - Realtime Database session handling
- `SessionManagerFirestore` - Firestore session handling
- `UserService` - Original Realtime Database service
- `UserServiceHybrid` - New service that works with both databases

### 2.4 Factory
- `RepositoryFactory` - Creates the appropriate implementation based on configuration

### 2.5 Utilities
- `DatabaseMigrator` - Helps migrate data between the databases

## 3. Database Schema

### 3.1 Firestore Schema

```
profit-grocery/ (firestore database)
├── users/
│   └── [userId]/
│       ├── phoneNumber: string
│       ├── name: string (optional)
│       ├── email: string (optional)
│       ├── addresses: array (optional)
│       ├── createdAt: timestamp
│       ├── lastLogin: timestamp
│       └── isOptedInForMarketing: boolean
│
├── sessions/
│   └── [userId]/
│       ├── token: string
│       ├── createdAt: timestamp
│       ├── expiresAt: timestamp
│       ├── lastActive: timestamp
│       └── deviceInfo: map
│
├── products/
│   └── [productId]/
│       ├── name: string
│       ├── description: string
│       ├── price: number
│       ├── images: array
│       ├── category: string
│       └── ...
│
└── orders/
    └── [orderId]/
        ├── userId: string
        ├── status: string
        ├── totalAmount: number
        ├── items: subcollection
        ├── createdAt: timestamp
        └── ...
```

### 3.2 Realtime Database Schema

```
profit-grocery-default-rtdb/ (realtime database)
├── cart/
│   └── [userId]/
│       └── [productId]/
│           ├── productId: string
│           ├── quantity: number
│           ├── price: number
│           └── addedAt: string
│
├── inventory/
│   └── [productId]/
│       ├── inStock: boolean
│       ├── quantity: number
│       └── updatedAt: string
│
├── promotions/
│   └── [promotionId]/
│       ├── title: string
│       ├── description: string
│       ├── imageUrl: string
│       ├── startDate: string
│       ├── endDate: string
│       └── ...
│
└── sessions/ (legacy, for backward compatibility)
    └── [userId]/
        ├── token: string
        ├── createdAt: string
        ├── expiresAt: string
        ├── lastActive: string
        └── deviceInfo: object
```

## 4. Configuration

The database preference is controlled through Firebase Remote Config:

- `prefer_firestore`: Boolean flag that determines which implementation to use
  - `true`: Use Firestore for authentication, user data, and session management
  - `false`: Use Realtime Database for these operations

Remote Config allows us to toggle between implementations without app updates.

## 5. Migration Strategy

A migration utility is provided to move data between databases:

1. **One-way migration**: Data flows from Realtime Database to Firestore
2. **Selective migration**: Only missing data is migrated (no overwriting)
3. **Collection migration**: Each collection is migrated separately
4. **Progressive migration**: Can be done in stages over time

An admin interface (`DataMigrationPage`) allows controlled migration.

## 6. Security Rules

Both databases implement security rules:

- **Firestore Rules**: More granular, document-level security
- **Realtime Database Rules**: Path-based security

Rules ensure that users can only access their own data, while allowing public access to product information.

## 7. Best Practices

When working with the hybrid approach:

1. **Use the right database for the job**:
   - Firestore for complex querying and structured data
   - Realtime Database for high-frequency updates and real-time syncing

2. **Respect the persistence model**:
   - Firestore uses documents and collections
   - Realtime Database uses a JSON tree

3. **Handle both data sources**:
   - Check for data in both databases during transitional period
   - Use the hybrid service where appropriate

4. **Consistent IDs**:
   - Use the same document/node IDs across both databases for the same entity

5. **Graceful degradation**:
   - If one database is unavailable, fall back to the other

## 8. Performance Considerations

The hybrid approach optimizes performance:

- **Reduced Firestore read operations**: Only used for infrequently accessed data
- **Faster real-time updates**: Realtime Database for high-frequency changes
- **Better query capabilities**: Firestore for complex data retrieval
- **Offline capability**: Both databases support offline persistence

## 9. Future Considerations

As the application evolves:

1. **Complete migration**: Eventually move entirely to Firestore
2. **Feature flags**: Use remote config to enable/disable features based on database availability
3. **Versioned APIs**: Support multiple database versions in the app
4. **Analytics**: Monitor database performance and adjust the strategy accordingly