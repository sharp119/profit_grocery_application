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

// List of all category groups
const CATEGORY_GROUPS = [
  'bakeries_biscuits',
  'beauty_hygiene',
  'dairy_eggs',
  'fruits_vegetables',
  'grocery_kitchen',
  'snacks_drinks'
];

// Function to generate Firebase Storage URL
function generateStorageUrl(path) {
  // Remove leading slash if present
  path = path.startsWith('/') ? path.slice(1) : path;
  // Encode the path components
  const encodedPath = path.split('/').map(component => encodeURIComponent(component)).join('/');
  return `https://firebasestorage.googleapis.com/v0/b/${firebaseConfig.storageBucket}/o/${encodedPath}?alt=media`;
}

async function updateImagePaths(categoryGroup) {
  console.log(`\nUpdating image paths for category group: ${categoryGroup}`);
  console.log('='.repeat(50));
  
  try {
    // Get all items under this category
    const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
    let updatedCount = 0;
    let skippedCount = 0;
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      console.log(`\nProcessing ${categoryItem}...`);
      
      // Get all products under this item
      const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
      
      // Update each product with the complete image path
      for (const productDoc of productsSnapshot.docs) {
        const currentData = productDoc.data();
        const currentImagePath = currentData.imagePath;
        
        // Check if imagePath exists and is not in the correct format
        if (currentImagePath && !currentImagePath.startsWith('https://firebasestorage.googleapis.com')) {
          // If it's a gs:// URL, extract the path
          const path = currentImagePath.startsWith('gs://') 
            ? currentImagePath.replace(`gs://${firebaseConfig.storageBucket}/`, '')
            : `products/${categoryGroup}/${categoryItem}/${productDoc.id}/image`;
            
          const newImagePath = generateStorageUrl(path);
          
          await updateDoc(productDoc.ref, {
            imagePath: newImagePath
          });
          
          console.log(`  ✓ Updated: ${productDoc.id} - ${currentData.name}`);
          console.log(`    Old path: ${currentImagePath}`);
          console.log(`    New path: ${newImagePath}`);
          updatedCount++;
        } else if (!currentImagePath) {
          // If no imagePath exists, create one
          const path = `products/${categoryGroup}/${categoryItem}/${productDoc.id}/image`;
          const newImagePath = generateStorageUrl(path);
          
          await updateDoc(productDoc.ref, {
            imagePath: newImagePath
          });
          
          console.log(`  ✓ Created path for: ${productDoc.id} - ${currentData.name}`);
          console.log(`    New path: ${newImagePath}`);
          updatedCount++;
        } else {
          console.log(`  - Skipped: ${productDoc.id} - ${currentData.name} (Already has correct path)`);
          skippedCount++;
        }
      }
    }
    
    console.log('\n='.repeat(50));
    console.log(`Category ${categoryGroup} update complete!`);
    console.log(`Updated: ${updatedCount} products`);
    console.log(`Skipped: ${skippedCount} products`);
    
  } catch (error) {
    console.error(`Error during image path update for ${categoryGroup}:`, error);
    throw error;  // Re-throw to handle in the main function
  }
}

async function updateAllCategories() {
  console.log('Starting image path update for all categories...\n');
  
  for (const categoryGroup of CATEGORY_GROUPS) {
    try {
      await updateImagePaths(categoryGroup);
    } catch (error) {
      console.error(`Failed to update ${categoryGroup}:`, error);
      // Continue with next category even if one fails
    }
  }
}

// Get category from command line argument, otherwise update all categories
const categoryArg = process.argv[2];

if (categoryArg) {
  if (CATEGORY_GROUPS.includes(categoryArg)) {
    updateImagePaths(categoryArg).then(() => {
      console.log('\nAll done!');
      process.exit(0);
    }).catch((error) => {
      console.error('Script failed:', error);
      process.exit(1);
    });
  } else {
    console.error(`Invalid category: ${categoryArg}`);
    console.log('Available categories:', CATEGORY_GROUPS.join(', '));
    process.exit(1);
  }
} else {
  updateAllCategories().then(() => {
    console.log('\nAll categories updated successfully!');
    process.exit(0);
  }).catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });
}
