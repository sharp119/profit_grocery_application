import { initializeApp } from 'firebase/app';
import { getFirestore, doc, setDoc, collection } from 'firebase/firestore'; 
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

console.log('🚀 UPLOADING PRODUCT DETAILS TO FIRESTORE (NESTED STRUCTURE)');
console.log('📋 Reading transformed product data and uploading to "product_detail" collection with hierarchy...');
console.log('='.repeat(60));

// --- Configuration ---
const PRODUCTS_EXPORT_DIR = 'F:\\Soup\\projects\\profit_grocery_application\\db_upload'; 
const ROOT_COLLECTION = 'product_detail'; 

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

// --- Helper Functions ---

function findLatestTransformedProductsFile(directory) {
  try {
    const files = fs.readdirSync(directory);
    const transformedFiles = files.filter(file => file.startsWith('transformed_products_enhanced_export_') && file.endsWith('.json'));

    if (transformedFiles.length === 0) {
      console.error(`❌ No 'transformed_products_enhanced_export_*.json' files found in ${directory}`);
      return null;
    }

    const latestFile = transformedFiles.sort().reverse()[0];
    const latestPath = path.join(directory, latestFile);
    console.log(`✅ Found latest transformed product file: ${latestFile}`); 
    return latestPath;
  } catch (error) {
    console.error(`❌ Error finding latest file: ${error.message}`);
    return null;
  }
}

function loadJsonFile(filePath) {
  try {
    console.log(`📂 Loading: ${path.basename(filePath)}`);
    const data = fs.readFileSync(filePath, 'utf8');
    const parsed = JSON.parse(data);
    console.log(`✅ Successfully loaded ${path.basename(filePath)}`);
    return parsed;
  } catch (error) {
    console.error(`❌ Error loading ${filePath}:`, error.message);
    process.exit(1);
  }
}

// --- Main Upload Function ---

async function uploadProductDetails() {
  const latestFilePath = findLatestTransformedProductsFile(PRODUCTS_EXPORT_DIR);
  if (!latestFilePath) {
    process.exit(1);
  }

  const transformedData = loadJsonFile(latestFilePath);

  if (!transformedData || !transformedData.product_detail) { // Changed from .products to .product_detail as per input JSON
    console.error('❌ Invalid or empty transformed product data structure. Ensure it has a "product_detail" key at the root.');
    process.exit(1);
  }

  let uploadCount = 0;
  let errorCount = 0;

  console.log(`\nStarting upload to Firestore root collection: "${ROOT_COLLECTION}"`);
  console.log('='.repeat(60));

  try {
    // Correctly iterate over the 'product_detail' key which contains the category groups
    for (const categoryGroupKey in transformedData.product_detail) { 
      if (transformedData.product_detail.hasOwnProperty(categoryGroupKey)) {
        // Create document for category group (e.g., product_detail/bakeries_biscuits)
        const categoryGroupRef = doc(db, ROOT_COLLECTION, categoryGroupKey);
        await setDoc(categoryGroupRef, {}); // Create an empty document for the category group
        console.log(`  📁 Processing Category Group: ${categoryGroupKey}`);

        // Get reference to the 'items' subcollection
        const itemsCollectionRef = collection(categoryGroupRef, 'items');

        for (const categoryItemKey in transformedData.product_detail[categoryGroupKey]) {
          if (transformedData.product_detail[categoryGroupKey].hasOwnProperty(categoryItemKey)) {
            // Create document for category item (e.g., product_detail/bakeries_biscuits/items/bakery_snacks)
            const categoryItemRef = doc(itemsCollectionRef, categoryItemKey); // Using the explicit itemsCollectionRef
            await setDoc(categoryItemRef, {}); // Create an empty document for the category item
            console.log(`    📦 Processing Category Item: ${categoryItemKey}`);

            const productsArray = transformedData.product_detail[categoryGroupKey][categoryItemKey]; // Corrected access

            // Get reference to the 'products' subcollection
            const productsSubCollectionRef = collection(categoryItemRef, 'products');

            for (const product of productsArray) {
              if (!product.id) {
                console.error(`      ❌ Skipping product due to missing ID: ${JSON.stringify(product)}`);
                errorCount++;
                continue;
              }

              try {
                // Upload product to its nested path (e.g., product_detail/bakeries_biscuits/items/bakery_snacks/products/PRODUCT_ID)
                const productRef = doc(productsSubCollectionRef, product.id); // Using the explicit productsSubCollectionRef
                await setDoc(productRef, product); // Upload the entire structured product object

                console.log(`      ✅ Uploaded: ${product.id} - "${product.hero_section.name || 'Unnamed Product'}"`);
                uploadCount++;
              } catch (uploadError) {
                console.error(`      ❌ Error uploading product ${product.id}: ${uploadError.message}`);
                errorCount++;
              }
            }
          }
        }
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('🎉 PRODUCT DETAILS UPLOAD COMPLETED!');
    console.log('='.repeat(60));
    console.log(`📊 Total Products Processed: ${uploadCount + errorCount}`);
    console.log(`✅ Successfully Uploaded: ${uploadCount}`);
    console.log(`❌ Errors: ${errorCount}`);
    console.log('='.repeat(60));

  } catch (mainError) {
    console.error(`\n💥 Script failed during iteration: ${mainError.message}`);
    process.exit(1);
  }
}

// Run the script
uploadProductDetails().then(() => {
  console.log('Script execution finished.');
  process.exit(0);
}).catch((error) => {
  console.error(`Script crashed: ${error.message}`);
  process.exit(1);
});