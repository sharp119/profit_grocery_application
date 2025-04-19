import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, updateDoc } from 'firebase/firestore';
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

async function updateImagePaths(categoryGroup) {
  console.log(`\nUpdating image paths for category group: ${categoryGroup}`);
  console.log('='.repeat(50));
  
  try {
    // Get all items under this category
    const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      console.log(`Updating ${categoryItem}...`);
      
      // Get all products under this item
      const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
      
      // Update each product with the complete image path
      for (const productDoc of productsSnapshot.docs) {
        const currentData = productDoc.data();
        const currentImagePath = currentData.imagePath;
        
        // Check if imagePath exists and doesn't start with gs://
        if (currentImagePath && !currentImagePath.startsWith('gs://')) {
          const newImagePath = `gs://profit-grocery.firebasestorage.app/${currentImagePath}`;
          
          await updateDoc(productDoc.ref, {
            imagePath: newImagePath
          });
          
          console.log(`  ✓ Updated: ${productDoc.id} - ${currentData.name}`);
          console.log(`    Old path: ${currentImagePath}`);
          console.log(`    New path: ${newImagePath}`);
        } else if (!currentImagePath) {
          // If no imagePath exists, create one
          const newImagePath = `gs://profit-grocery.firebasestorage.app/products/${categoryGroup}/${categoryItem}/${productDoc.id}/image.png`;
          
          await updateDoc(productDoc.ref, {
            imagePath: newImagePath
          });
          
          console.log(`  ✓ Created path for: ${productDoc.id} - ${currentData.name}`);
          console.log(`    New path: ${newImagePath}`);
        } else {
          console.log(`  - Skipped: ${productDoc.id} - ${currentData.name} (Already has correct path)`);
        }
      }
    }
    
    console.log('\n='.repeat(50));
    console.log('Update complete!');
    
  } catch (error) {
    console.error('Error during image path update:', error);
  }
}

// Run the update script
updateImagePaths('bakeries_biscuits').then(() => {
  console.log('\nAll done!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
