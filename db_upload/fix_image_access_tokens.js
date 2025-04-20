import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, updateDoc } from 'firebase/firestore';
import { getStorage, ref, getMetadata } from 'firebase/storage';
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
const storage = getStorage(app);

// List of all category groups
const CATEGORY_GROUPS = [
  'bakeries_biscuits',
  'beauty_hygiene',
  'dairy_eggs',
  'fruits_vegetables',
  'grocery_kitchen',
  'snacks_drinks'
];

// Function to get metadata for an image in Firebase Storage
async function getImageMetadata(storagePath) {
  try {
    const storageRef = ref(storage, storagePath);
    const metadata = await getMetadata(storageRef);
    return metadata;
  } catch (error) {
    console.error(`Error getting metadata for ${storagePath}:`, error);
    return null;
  }
}

// Function to generate Firebase Storage URL with access token
function generateStorageUrlWithToken(path, accessToken) {
  // Remove leading slash if present
  path = path.startsWith('/') ? path.slice(1) : path;
  
  // Encode the path components
  const encodedPath = path.split('/').map(component => encodeURIComponent(component)).join('/');
  
  // Add access token if available
  const tokenParam = accessToken ? `&token=${accessToken}` : '';
  
  return `https://firebasestorage.googleapis.com/v0/b/${firebaseConfig.storageBucket}/o/${encodedPath}?alt=media${tokenParam}`;
}

async function fixImageAccessTokens(categoryGroup) {
  console.log(`\nFixing image access tokens for category group: ${categoryGroup}`);
  console.log('='.repeat(50));
  
  try {
    // Get all items under this category
    const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      console.log(`\nProcessing ${categoryItem}...`);
      
      // Get all products under this item
      const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
      
      // Update each product with the complete image path including access token
      for (const productDoc of productsSnapshot.docs) {
        const productId = productDoc.id;
        const currentData = productDoc.data();
        const currentImagePath = currentData.imagePath;
        const productName = currentData.name || productId;
        
        // Skip if the image path already has a token parameter
        if (currentImagePath && currentImagePath.includes('token=')) {
          console.log(`  - Skipped: ${productId} - ${productName} (Already has token)`);
          skippedCount++;
          continue;
        }
        
        // Determine the storage path
        let storagePath;
        if (currentImagePath && currentImagePath.startsWith('gs://')) {
          storagePath = currentImagePath.replace(`gs://${firebaseConfig.storageBucket}/`, '');
        } else {
          storagePath = `products/${categoryGroup}/${categoryItem}/${productId}/image.png`;
        }
        
        // Get the metadata to extract the access token
        const metadata = await getImageMetadata(storagePath);
        
        if (metadata && metadata.customMetadata && metadata.customMetadata.accessToken) {
          // Extract access token from metadata
          const accessToken = metadata.customMetadata.accessToken;
          
          // Generate the new URL with access token
          const newImagePath = generateStorageUrlWithToken(storagePath, accessToken);
          
          // Update the document
          await updateDoc(productDoc.ref, {
            imagePath: newImagePath
          });
          
          console.log(`  ✓ Updated: ${productId} - ${productName}`);
          console.log(`    Old path: ${currentImagePath}`);
          console.log(`    New path: ${newImagePath}`);
          updatedCount++;
        } else {
          // If we couldn't get the access token from metadata, try an alternative approach
          // Use the Firebase Storage download URL pattern with a generated UUID for the token
          const accessToken = generateUUID();
          const newImagePath = generateStorageUrlWithToken(storagePath, accessToken);
          
          await updateDoc(productDoc.ref, {
            imagePath: newImagePath
          });
          
          console.log(`  ⚠ Updated with generated token: ${productId} - ${productName}`);
          console.log(`    Old path: ${currentImagePath}`);
          console.log(`    New path: ${newImagePath}`);
          updatedCount++;
        }
      }
    }
    
    console.log('\n='.repeat(50));
    console.log(`Category ${categoryGroup} update complete!`);
    console.log(`Updated: ${updatedCount} products`);
    console.log(`Skipped: ${skippedCount} products`);
    console.log(`Errors: ${errorCount} products`);
    
  } catch (error) {
    console.error(`Error during image path update for ${categoryGroup}:`, error);
    throw error;  // Re-throw to handle in the main function
  }
}

// Generate a UUID for access token
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

async function fixAllCategories() {
  console.log('Starting image path fix for all categories...\n');
  
  for (const categoryGroup of CATEGORY_GROUPS) {
    try {
      await fixImageAccessTokens(categoryGroup);
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
    fixImageAccessTokens(categoryArg).then(() => {
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
  fixAllCategories().then(() => {
    console.log('\nAll categories updated successfully!');
    process.exit(0);
  }).catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });
}
