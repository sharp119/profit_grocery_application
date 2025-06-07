# Firebase Database Indexing Fix

## Issue
The application is encountering a Firebase Realtime Database indexing error when checking if users exist by phone number. 
This happens because we're querying the database by `phoneNumber` but haven't defined an index for that field.

The error looks like this:
```
[firebase_database/index-not-defined] Index not defined, add ".indexOn".
```

## Solution

### 1. Update your Firebase Realtime Database Rules

In your Firebase console:
1. Go to Realtime Database
2. Select the "Rules" tab
3. Update your rules to include an index on `phoneNumber` in the `users` collection:

```json
{
  "rules": {
    "users": {
      ".indexOn": ["phoneNumber"],
      "$userId": {
        ".read": "auth.uid === $userId",
        ".write": "auth.uid === $userId || !data.exists()"
      }
    },
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

4. Click "Publish" to save the changes

### 2. Deploy the Rules from CLI (Alternative)

If you prefer using Firebase CLI:

1. Make sure the `database.rules.json` file in your project has the correct rules
2. Run the following command to deploy:
```
firebase deploy --only database
```

### 3. Verify the Fix

After updating the rules:
1. Restart the app
2. Try logging in with an existing phone number
3. The app should now correctly identify if the user exists and navigate to the appropriate flow

## More Information

- The app has been updated to handle this error gracefully and continue with the registration flow
- We've added a try-catch block specifically for Realtime Database queries
- The app now prioritizes Firestore for user lookups

For more details, see Firebase documentation on [indexing your data](https://firebase.google.com/docs/database/security/indexing-data).