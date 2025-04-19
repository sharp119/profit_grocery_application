import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, setDoc } from 'firebase/firestore';
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

async function createProductsStructure() {
  try {
    console.log('Starting to create products structure...');
    console.log('==================================');
    
    // Get all categories
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id;
      console.log(`\nCreating product group: ${categoryId}`);
      
      // Create empty product group document with same ID
      const productRef = doc(db, 'products', categoryId);
      await setDoc(productRef, {}); // Empty document
      
      // Check for items subcollection
      const itemsSnapshot = await getDocs(collection(db, 'categories', categoryId, 'items'));
      
      if (!itemsSnapshot.empty) {
        console.log(`  Creating items subcollection for: ${categoryId}`);
        
        for (const itemDoc of itemsSnapshot.docs) {
          const itemId = itemDoc.id;
          console.log(`    Creating item: ${itemId}`);
          
          // Create empty item document with same ID
          const itemRef = doc(db, 'products', categoryId, 'items', itemId);
          await setDoc(itemRef, {}); // Empty document
        }
      } else {
        console.log(`  No items subcollection for: ${categoryId}`);
      }
    }
    
    console.log('\n==================================');
    console.log('Products structure created successfully!');
    
  } catch (error) {
    console.error('Error creating products structure:', error);
  }
}

// Add a preview mode to see what would be created without actually creating it
async function previewProductsStructure() {
  try {
    console.log('PREVIEW MODE: Showing what would be created...');
    console.log('============================================');
    
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id;
      console.log(`\nProduct group: ${categoryId}`);
      
      const itemsSnapshot = await getDocs(collection(db, 'categories', categoryId, 'items'));
      
      if (!itemsSnapshot.empty) {
        console.log('  Items:');
        for (const itemDoc of itemsSnapshot.docs) {
          console.log(`    - ${itemDoc.id}`);
        }
      } else {
        console.log('  No items subcollection');
      }
    }
    
    console.log('\n============================================');
    console.log('End of preview');
    
  } catch (error) {
    console.error('Error in preview:', error);
  }
}

// Command line argument parsing
const args = process.argv.slice(2);
const isPreview = args.includes('--preview');

if (isPreview) {
  previewProductsStructure().then(() => process.exit(0));
} else {
  createProductsStructure().then(() => process.exit(0));
}
