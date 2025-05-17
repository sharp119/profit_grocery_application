import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, setDoc } from 'firebase/firestore';
import { getDatabase, ref, set as rtdSet } from 'firebase/database';
import dotenv from 'dotenv';

// Load environment variables
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

const CATEGORY_GROUPS = [
  'bakeries_biscuits',
  'beauty_hygiene',
  'dairy_eggs',
  'fruits_vegetables',
  'grocery_kitchen',
  'snacks_drinks'
];

const DYNAMIC_FIELDS = ['price', 'quantity', 'inStock', 'hasDiscount', 'updatedAt'];

async function migrateProducts() {
  console.log('Starting migration of products to Firestore + RTD split...');
  let totalMigrated = 0;
  let totalErrors = 0;

  for (const categoryGroup of CATEGORY_GROUPS) {
    console.log(`\nProcessing category group: ${categoryGroup}`);
    try {
      const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      for (const itemDoc of itemsSnapshot.docs) {
        const categoryItem = itemDoc.id;
        console.log(`  Processing item: ${categoryItem}`);
        const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
        for (const productDoc of productsSnapshot.docs) {
          const productId = productDoc.id;
          const productData = productDoc.data();

          // Split static and dynamic fields
          const staticData = { ...productData };
          const dynamicData = {};
          for (const field of DYNAMIC_FIELDS) {
            if (field in staticData) {
              dynamicData[field] = staticData[field];
              delete staticData[field];
            }
          }

          // Overwrite Firestore doc with static data
          try {
            await setDoc(doc(db, 'products', categoryGroup, 'items', categoryItem, 'products', productId), staticData, { merge: false });
            console.log(`    ✓ Firestore static data updated for ${productId}`);
          } catch (err) {
            console.error(`    ✗ Error updating Firestore for ${productId}:`, err);
            totalErrors++;
            continue;
          }

          // Upload dynamic data to RTD
          try {
            const rtdPath = `products/${categoryGroup}/items/${categoryItem}/products/${productId}`;
            await rtdSet(ref(rtdb, rtdPath), dynamicData);
            console.log(`    ✓ RTD dynamic data set for ${productId}`);
          } catch (err) {
            console.error(`    ✗ Error setting RTD for ${productId}:`, err);
            totalErrors++;
            continue;
          }

          totalMigrated++;
        }
      }
    } catch (err) {
      console.error(`  ✗ Error processing group/item:`, err);
      totalErrors++;
    }
  }
  console.log(`\nMigration complete. Total migrated: ${totalMigrated}, Errors: ${totalErrors}`);
}

migrateProducts().then(() => process.exit(0)).catch((err) => {
  console.error('Fatal error during migration:', err);
  process.exit(1);
}); 