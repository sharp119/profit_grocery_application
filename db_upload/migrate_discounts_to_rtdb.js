import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { getDatabase, ref, set as rtdSet } from 'firebase/database';
import dotenv from 'dotenv';

dotenv.config();

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DATABASE_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const rtdb = getDatabase(app);

async function migrateDiscounts() {
  console.log('Starting migration of discounts from Firestore to RTDB...');
  let totalMigrated = 0;
  let totalErrors = 0;

  try {
    const discountsSnapshot = await getDocs(collection(db, 'discounts'));
    if (discountsSnapshot.empty) {
      console.log('No discounts found in Firestore.');
      return;
    }
    for (const docSnap of discountsSnapshot.docs) {
      const discountId = docSnap.id;
      const discountData = docSnap.data();
      try {
        await rtdSet(ref(rtdb, `discounts/${discountId}`), discountData);
        console.log(`  ✓ Migrated discount for productId: ${discountId}`);
        totalMigrated++;
      } catch (err) {
        console.error(`  ✗ Error migrating discount for productId: ${discountId}:`, err);
        totalErrors++;
      }
    }
  } catch (err) {
    console.error('Fatal error fetching discounts from Firestore:', err);
    totalErrors++;
  }
  console.log(`\nDiscount migration complete. Total migrated: ${totalMigrated}, Errors: ${totalErrors}`);
}

migrateDiscounts().then(() => process.exit(0)).catch((err) => {
  console.error('Fatal error during migration:', err);
  process.exit(1);
}); 