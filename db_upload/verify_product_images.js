import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { getStorage, ref, getDownloadURL } from 'firebase/storage';
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

// Function to check if an image exists in storage
async function checkImageExists(storagePath) {
  try {
    const storageRef = ref(storage, storagePath);
    const url = await getDownloadURL(storageRef);
    return { exists: true, url };
  } catch (error) {
    return { exists: false, error: error.message };
  }
}

// Function to verify all product images
async function verifyProductImages() {
  console.log('\nVerifying product images in Firebase Storage...');
  console.log('=============================================');
  
  let totalProducts = 0;
  let imagesFound = 0;
  let imagesMissing = 0;
  
  try {
    // Get all category groups from the products collection
    const categoryGroupsSnapshot = await getDocs(collection(db, 'products'));
    
    for (const categoryGroupDoc of categoryGroupsSnapshot.docs) {
      const categoryGroup = categoryGroupDoc.id;
      console.log(`\nVerifying category group: ${categoryGroup}`);
      
      // Get all category items under this group
      const categoryItemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      
      for (const categoryItemDoc of categoryItemsSnapshot.docs) {
        const categoryItem = categoryItemDoc.id;
        console.log(`  Verifying category item: ${categoryItem}`);
        
        // Get all products under this item
        const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
        
        for (const productDoc of productsSnapshot.docs) {
          totalProducts++;
          const productData = productDoc.data();
          const productId = productDoc.id;
          
          // Get the storage path from the product data
          const imagePath = productData.imagePath;
          
          if (!imagePath || !imagePath.startsWith('gs://')) {
            console.error(`    Invalid image path for product: ${productId} - ${productData.name}`);
            imagesMissing++;
            continue;
          }
          
          // Extract just the path portion after the bucket name
          const storagePath = imagePath.replace(`gs://${firebaseConfig.storageBucket}/`, '');
          
          // Check if the image exists
          const result = await checkImageExists(storagePath);
          
          if (result.exists) {
            console.log(`    ✓ Image found for: ${productData.name}`);
            imagesFound++;
          } else {
            console.error(`    ✗ Image missing for: ${productData.name}`);
            console.error(`      Error: ${result.error}`);
            imagesMissing++;
          }
        }
      }
    }
    
    console.log('\n=============================================');
    console.log(`Verification complete!`);
    console.log(`Total products: ${totalProducts}`);
    console.log(`Images found: ${imagesFound}`);
    console.log(`Images missing: ${imagesMissing}`);
    console.log(`Success rate: ${((imagesFound / totalProducts) * 100).toFixed(2)}%`);
    
  } catch (error) {
    console.error('Error verifying products:', error);
  }
}

// Run the verification
verifyProductImages().then(() => {
  console.log('\nDone!');
  process.exit(0);
}).catch((error) => {
  console.error('Failed to verify images:', error);
  process.exit(1);
});
