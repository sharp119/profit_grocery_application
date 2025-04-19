import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { getStorage, ref, uploadBytes } from 'firebase/storage';
import fs from 'fs';
import path from 'path';
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

// Path to the products folder containing images
const IMAGES_FOLDER = path.join(process.cwd(), 'products');

// Function to get all image files from the products folder
function getAllImages() {
  try {
    // Check if the products folder exists
    if (!fs.existsSync(IMAGES_FOLDER)) {
      console.error(`Images folder not found at: ${IMAGES_FOLDER}`);
      return [];
    }

    // Get all files in the products folder
    const files = fs.readdirSync(IMAGES_FOLDER);
    
    // Filter for image files (jpg, jpeg, png, webp)
    const imageFiles = files.filter(file => {
      const ext = path.extname(file).toLowerCase();
      return ['.jpg', '.jpeg', '.png', '.webp'].includes(ext);
    });

    console.log(`Found ${imageFiles.length} images in the products folder`);
    return imageFiles;
  } catch (error) {
    console.error('Error reading images folder:', error);
    return [];
  }
}

// Function to get a random image from the array
function getRandomImage(images) {
  if (images.length === 0) {
    throw new Error('No images available');
  }
  const randomIndex = Math.floor(Math.random() * images.length);
  return images[randomIndex];
}

// Function to upload an image to Firebase Storage
async function uploadImageToStorage(localImagePath, storagePath) {
  try {
    // Read the file
    const fileBuffer = fs.readFileSync(localImagePath);
    
    // Create a reference to the storage location
    const storageRef = ref(storage, storagePath);
    
    // Upload the file
    const snapshot = await uploadBytes(storageRef, fileBuffer, {
      contentType: 'image/png' // We'll save all as PNG in storage
    });
    
    console.log(`  ✓ Uploaded: ${path.basename(localImagePath)} → ${storagePath}`);
    return true;
  } catch (error) {
    console.error(`  ✗ Error uploading ${path.basename(localImagePath)}: ${error.message}`);
    return false;
  }
}

// Function to process and upload images for all products
async function uploadProductImages() {
  console.log('\nStarting product image upload...');
  console.log('===============================');
  
  // Get all available images
  const availableImages = getAllImages();
  
  if (availableImages.length === 0) {
    console.error('No images found in the products folder. Exiting...');
    return;
  }
  
  let totalUploaded = 0;
  let totalErrors = 0;
  
  try {
    // Get all category groups from the products collection
    const categoryGroupsSnapshot = await getDocs(collection(db, 'products'));
    
    for (const categoryGroupDoc of categoryGroupsSnapshot.docs) {
      const categoryGroup = categoryGroupDoc.id;
      console.log(`\nProcessing category group: ${categoryGroup}`);
      
      // Get all category items under this group
      const categoryItemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      
      for (const categoryItemDoc of categoryItemsSnapshot.docs) {
        const categoryItem = categoryItemDoc.id;
        console.log(`  Processing category item: ${categoryItem}`);
        
        // Get all products under this item
        const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
        
        for (const productDoc of productsSnapshot.docs) {
          const productId = productDoc.id;
          const productData = productDoc.data();
          
          // Get the storage path from the product data
          const imagePath = productData.imagePath;
          
          if (!imagePath || !imagePath.startsWith('gs://')) {
            console.error(`    Invalid image path for product: ${productId}`);
            totalErrors++;
            continue;
          }
          
          // Extract just the path portion after the bucket name
          const storagePath = imagePath.replace(`gs://${firebaseConfig.storageBucket}/`, '');
          
          // Select a random image
          const randomImage = getRandomImage(availableImages);
          const localImagePath = path.join(IMAGES_FOLDER, randomImage);
          
          // Upload the image
          const uploaded = await uploadImageToStorage(localImagePath, storagePath);
          
          if (uploaded) {
            totalUploaded++;
          } else {
            totalErrors++;
          }
        }
      }
    }
    
    console.log('\n===============================');
    console.log(`Upload complete!`);
    console.log(`Successfully uploaded: ${totalUploaded} images`);
    console.log(`Errors: ${totalErrors}`);
    
  } catch (error) {
    console.error('Error processing products:', error);
  }
}

// Alternative function to upload images for a specific category
async function uploadImagesForCategory(categoryGroup) {
  console.log(`\nUploading images for category: ${categoryGroup}`);
  console.log('===============================');
  
  // Get all available images
  const availableImages = getAllImages();
  
  if (availableImages.length === 0) {
    console.error('No images found in the products folder. Exiting...');
    return;
  }
  
  let totalUploaded = 0;
  let totalErrors = 0;
  
  try {
    // Get all category items under this group
    const categoryItemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
    
    for (const categoryItemDoc of categoryItemsSnapshot.docs) {
      const categoryItem = categoryItemDoc.id;
      console.log(`  Processing category item: ${categoryItem}`);
      
      // Get all products under this item
      const productsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'));
      
      for (const productDoc of productsSnapshot.docs) {
        const productId = productDoc.id;
        const productData = productDoc.data();
        
        // Get the storage path from the product data
        const imagePath = productData.imagePath;
        
        if (!imagePath || !imagePath.startsWith('gs://')) {
          console.error(`    Invalid image path for product: ${productId}`);
          totalErrors++;
          continue;
        }
        
        // Extract just the path portion after the bucket name
        const storagePath = imagePath.replace(`gs://${firebaseConfig.storageBucket}/`, '');
        
        // Select a random image
        const randomImage = getRandomImage(availableImages);
        const localImagePath = path.join(IMAGES_FOLDER, randomImage);
        
        // Upload the image
        const uploaded = await uploadImageToStorage(localImagePath, storagePath);
        
        if (uploaded) {
          totalUploaded++;
        } else {
          totalErrors++;
        }
      }
    }
    
    console.log('\n===============================');
    console.log(`Upload complete for ${categoryGroup}!`);
    console.log(`Successfully uploaded: ${totalUploaded} images`);
    console.log(`Errors: ${totalErrors}`);
    
  } catch (error) {
    console.error(`Error processing category ${categoryGroup}:`, error);
  }
}

// Check if a specific category was provided as an argument
const args = process.argv.slice(2);
const categoryToUpload = args[0];

if (categoryToUpload) {
  // Upload images for a specific category
  uploadImagesForCategory(categoryToUpload).then(() => {
    console.log('\nDone!');
    process.exit(0);
  }).catch((error) => {
    console.error('Failed to upload images:', error);
    process.exit(1);
  });
} else {
  // Upload images for all categories
  uploadProductImages().then(() => {
    console.log('\nDone!');
    process.exit(0);
  }).catch((error) => {
    console.error('Failed to upload images:', error);
    process.exit(1);
  });
}
