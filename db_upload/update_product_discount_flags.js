/**
 * update_product_discount_flags.js
 * 
 * This script adds a 'hasDiscount' field to all products in the database.
 * It sets the field to true if the product ID exists in the discounts collection,
 * and false if it doesn't.
 * 
 * The script only adds/updates the hasDiscount field without modifying any existing data.
 */

import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  doc, 
  updateDoc, 
  getDoc 
} from 'firebase/firestore';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs';

// ES modules equivalent for the require.main === module pattern
const __filename = fileURLToPath(import.meta.url);
const isMainModule = process.argv[1] === __filename;

// Load environment variables
dotenv.config();

// Initialize Firebase configuration
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

/**
 * Get all discount IDs from the discounts collection
 * @returns {Promise<Set<string>>} A set of product IDs that have discounts
 */
async function getAllDiscountIds() {
  console.log('🔍 Fetching all discount IDs...');
  
  try {
    const discountsSnapshot = await getDocs(collection(db, 'discounts'));
    
    const discountIds = new Set();
    
    discountsSnapshot.forEach(discountDoc => {
      discountIds.add(discountDoc.id);
    });
    
    console.log(`✅ Found ${discountIds.size} discount IDs`);
    return discountIds;
  } catch (error) {
    console.error('❌ Error fetching discount IDs:', error);
    return new Set();
  }
}

/**
 * Verify category groups exist in Firestore
 * @returns {Promise<Array<string>>} List of verified category groups
 */
async function verifyCategoryGroups() {
  console.log('\n🔍 Verifying category groups in Firestore...');
  
  // Initial list of potential category groups
  const potentialGroups = [
    'bakeries_biscuits',
    'beauty_personal_care',
    'beauty_hygiene',
    'dairy_bread',
    'dairy_eggs',
    'fruits_vegetables',
    'grocery_kitchen',
    'snacks_drinks'
  ];
  
  const verifiedGroups = [];
  
  for (const group of potentialGroups) {
    try {
      const docRef = doc(db, 'products', group);
      const docSnap = await getDoc(docRef);
      
      if (docSnap.exists()) {
        console.log(`  ✅ Verified category group: ${group}`);
        verifiedGroups.push(group);
      } else {
        console.log(`  ❌ Category group does not exist: ${group}`);
      }
    } catch (error) {
      console.error(`  ❌ Error checking category group ${group}:`, error);
    }
  }
  
  if (verifiedGroups.length === 0) {
    console.error('  ❌ No valid category groups found. Please check your Firestore structure.');
  } else {
    console.log(`  ✅ Found ${verifiedGroups.length} valid category groups`);
  }
  
  return verifiedGroups;
}

/**
 * Update all products with the hasDiscount field
 * @param {Set<string>} discountIds Set of product IDs that have discounts
 * @returns {Promise<Object>} Statistics about the update operation
 */
async function updateProductDiscountFlags(discountIds) {
  console.log('\n📝 Updating product discount flags...');
  
  const stats = {
    total: 0,
    withDiscount: 0,
    withoutDiscount: 0,
    errors: 0,
    skipped: 0
  };
  
  // Get verified category groups from Firestore
  const CATEGORY_GROUPS = await verifyCategoryGroups();
  
  for (const categoryGroup of CATEGORY_GROUPS) {
    console.log(`\n🔍 Processing category group: ${categoryGroup}`);
    
    try {
      console.log(`  🔍 Checking category group path: products/${categoryGroup}/items`);
      
      // Get all items under this category
      const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      
      if (itemsSnapshot.empty) {
        console.log(`  ⚠️ Warning: No items found in category group: ${categoryGroup}`);
        continue;
      }
      
      console.log(`  ✅ Found ${itemsSnapshot.docs.length} items in category group: ${categoryGroup}`);
      
      for (const itemDoc of itemsSnapshot.docs) {
        const categoryItem = itemDoc.id;
        console.log(`  📂 Processing category item: ${categoryItem}`);
        
        // Get all products under this item
        const productsPath = `products/${categoryGroup}/items/${categoryItem}/products`;
        const productsSnapshot = await getDocs(collection(db, productsPath));
        
        let itemProductCount = 0;
        
        for (const productDoc of productsSnapshot.docs) {
          const productId = productDoc.id;
          const productData = productDoc.data();
          stats.total++;
          itemProductCount++;
          
          try {
            // If hasDiscount field already exists with the correct value, skip update
            if (productData.hasDiscount === true && discountIds.has(productId)) {
              console.log(`    ⏩ Skipping ${productId} - already marked as having discount`);
              stats.skipped++;
              continue;
            }
            
            if (productData.hasDiscount === false && !discountIds.has(productId)) {
              console.log(`    ⏩ Skipping ${productId} - already marked as not having discount`);
              stats.skipped++;
              continue;
            }
            
            // Check if product has a discount
            const hasDiscount = discountIds.has(productId);
            
            // Update the product document
            const productRef = doc(db, productsPath, productId);
            await updateDoc(productRef, {
              hasDiscount: hasDiscount
            });
            
            if (hasDiscount) {
              console.log(`    ✅ Updated ${productId} (${productData.name}) - HAS discount`);
              stats.withDiscount++;
            } else {
              console.log(`    ❌ Updated ${productId} (${productData.name}) - NO discount`);
              stats.withoutDiscount++;
            }
          } catch (error) {
            console.error(`    ❌ Error updating product ${productId}:`, error);
            stats.errors++;
          }
        }
        
        console.log(`  📊 Processed ${itemProductCount} products in ${categoryItem}`);
      }
    } catch (error) {
      console.error(`❌ Error processing category group ${categoryGroup}:`, error);
    }
  }
  
  return stats;
}

/**
 * Generate a timestamped log filename
 * @returns {string} Filename with timestamp
 */
function getLogFilename() {
  const now = new Date();
  const dateString = now.toISOString().split('T')[0]; // YYYY-MM-DD format
  const timeString = now.toISOString().split('T')[1].split('.')[0].replace(/:/g, '-'); // HH-MM-SS
  return `discount_flag_update_${dateString}_${timeString}.log`;
}

/**
 * Save log to file
 * @param {string} logContent Log content
 * @param {string} filename Log filename
 */
function saveLogToFile(logContent, filename) {
  try {
    fs.writeFileSync(filename, logContent);
    console.log(`\n✅ Log saved to ${filename}`);
  } catch (error) {
    console.error(`❌ Error saving log:`, error);
  }
}

/**
 * Main function to update product discount flags
 */
async function updateDiscountFlags() {
  console.log('🚀 Starting product discount flag update...');
  console.log('⏱️ ' + new Date().toISOString());
  
  // Capture console output
  const originalConsoleLog = console.log;
  const originalConsoleError = console.error;
  
  let logContent = '';
  
  // Override console methods to capture output
  console.log = function() {
    const message = Array.from(arguments).join(' ');
    logContent += message + '\n';
    originalConsoleLog.apply(console, arguments);
  };
  
  console.error = function() {
    const message = Array.from(arguments).join(' ');
    logContent += '❌ ERROR: ' + message + '\n';
    originalConsoleError.apply(console, arguments);
  };
  
  try {
    console.log('🔍 Fetching discount IDs...');
    const discountIds = await getAllDiscountIds();
    
    // Use the discount IDs to update products
    const stats = await updateProductDiscountFlags(discountIds);
    
    // Display summary
    console.log('\n📊 SUMMARY:');
    console.log('===============================');
    console.log(`Total products processed: ${stats.total}`);
    console.log(`Products with discount: ${stats.withDiscount}`);
    console.log(`Products without discount: ${stats.withoutDiscount}`);
    console.log(`Products skipped (no changes needed): ${stats.skipped}`);
    console.log(`Errors encountered: ${stats.errors}`);
    console.log('===============================');
    console.log('⏱️ Completed at: ' + new Date().toISOString());
    
    // Save log to file
    const logFilename = getLogFilename();
    saveLogToFile(logContent, logFilename);
    
    // Restore original console methods
    console.log = originalConsoleLog;
    console.error = originalConsoleError;
    
    console.log('\n✅ Product discount flag update completed successfully!');
  } catch (error) {
    console.error('\n❌ Error during discount flag update:', error);
    
    // Restore original console methods
    console.log = originalConsoleLog;
    console.error = originalConsoleError;
    
    // Save log even on error
    const logFilename = getLogFilename();
    saveLogToFile(logContent, logFilename);
  }
}

// Execute the script if run directly
if (isMainModule) {
  updateDiscountFlags()
    .then(() => {
      console.log('\n✅ Script completed.');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Script failed:', error);
      process.exit(1);
    });
}

export { updateDiscountFlags, getAllDiscountIds, updateProductDiscountFlags };
