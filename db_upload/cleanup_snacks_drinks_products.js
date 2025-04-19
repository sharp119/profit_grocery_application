import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, deleteDoc, doc } from 'firebase/firestore';
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

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function cleanupProducts(categoryGroup) {
  console.log(`\nCleaning up products for category group: ${categoryGroup}`);
  console.log('='.repeat(50));
  
  try {
    // Get all items under this category
    const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      console.log(`Cleaning up ${categoryItem}...`);
      
      // Get all products under this item
      const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
      
      // Delete each product
      for (const productDoc of productsSnapshot.docs) {
        await deleteDoc(doc(db, 'products', categoryGroup, 'items', categoryItem, 'products', productDoc.id));
        console.log(`  ✓ Deleted: ${productDoc.id}`);
      }
    }
    
    console.log('\n='.repeat(50));
    console.log('Cleanup complete!');
    
  } catch (error) {
    console.error('Error during cleanup:', error);
  }
}

// Run cleanup only if explicitly requested
const args = process.argv.slice(2);
if (args.includes('--confirm')) {
  cleanupProducts('snacks_drinks').then(() => {
    console.log('\nAll done!');
    process.exit(0);
  }).catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });
} else {
  console.log('This script will delete all products in the snacks_drinks category.');
  console.log('To confirm, run with --confirm flag');
  process.exit(0);
}
