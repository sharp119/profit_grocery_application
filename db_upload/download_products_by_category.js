import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
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

// Function to download products from a specific category group
async function downloadProductsFromCategory(categoryGroup) {
  console.log(`🎯 Downloading products from category: ${categoryGroup}`);
  console.log('='.repeat(50));
  
  const startTime = Date.now();
  let totalProductsDownloaded = 0;
  
  try {
    // Check if the category group exists
    const itemsRef = collection(db, 'products', categoryGroup, 'items');
    const itemsSnapshot = await getDocs(itemsRef);
    
    if (itemsSnapshot.empty) {
      console.log(`❌ Category group '${categoryGroup}' not found or has no items.`);
      return null;
    }
    
    console.log(`📁 Found ${itemsSnapshot.docs.length} category items in '${categoryGroup}'`);
    
    const categoryProducts = {};
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      console.log(`  📦 Processing: ${categoryItem}`);
      
      try {
        const productsRef = collection(db, 'products', categoryGroup, 'items', categoryItem, 'products');
        const productsSnapshot = await getDocs(productsRef);
        
        const products = [];
        
        productsSnapshot.forEach((productDoc) => {
          const productData = productDoc.data();
          
          const product = {
            id: productDoc.id,
            ...productData,
            createdAt: productData.createdAt?.toDate?.()?.toISOString() || productData.createdAt,
            updatedAt: productData.updatedAt?.toDate?.()?.toISOString() || productData.updatedAt
          };
          
          products.push(product);
        });
        
        if (products.length > 0) {
          categoryProducts[categoryItem] = products;
          totalProductsDownloaded += products.length;
          console.log(`    ✅ Downloaded ${products.length} products`);
        } else {
          console.log(`    ⚠️  No products found`);
        }
        
      } catch (error) {
        console.error(`    ❌ Error downloading from ${categoryItem}:`, error.message);
      }
    }
    
    // Create export data
    const exportData = {
      metadata: {
        exportDate: new Date().toISOString(),
        categoryGroup: categoryGroup,
        totalCategoryItems: Object.keys(categoryProducts).length,
        totalProducts: totalProductsDownloaded,
        exportDurationMs: Date.now() - startTime,
        firebaseProject: process.env.FIREBASE_PROJECT_ID
      },
      products: {
        [categoryGroup]: categoryProducts
      }
    };
    
    // Generate filename with timestamp
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `products_${categoryGroup}_${timestamp}.json`;
    const filepath = path.join(process.cwd(), filename);
    
    // Save to JSON file
    fs.writeFileSync(filepath, JSON.stringify(exportData, null, 2), 'utf8');
    
    console.log('\n' + '='.repeat(50));
    console.log('🎉 EXPORT COMPLETED SUCCESSFULLY!');
    console.log('='.repeat(50));
    console.log(`📊 Total Products Downloaded: ${totalProductsDownloaded}`);
    console.log(`📋 Total Category Items: ${Object.keys(categoryProducts).length}`);
    console.log(`⏱️  Export Duration: ${(Date.now() - startTime) / 1000} seconds`);
    console.log(`💾 Export saved to: ${filename}`);
    console.log('='.repeat(50));
    
    return exportData;
    
  } catch (error) {
    console.error('\n❌ EXPORT FAILED:');
    console.error('Error:', error.message);
    throw error;
  }
}

// Function to list available category groups
async function listAvailableCategoryGroups() {
  try {
    console.log('📂 Available category groups:');
    console.log('-'.repeat(30));
    
    const productsRef = collection(db, 'products');
    const categoryGroupsSnapshot = await getDocs(productsRef);
    
    const categoryGroups = [];
    
    for (const categoryGroupDoc of categoryGroupsSnapshot.docs) {
      const categoryGroup = categoryGroupDoc.id;
      categoryGroups.push(categoryGroup);
      
      // Count items in this category group
      try {
        const itemsRef = collection(db, 'products', categoryGroup, 'items');
        const itemsSnapshot = await getDocs(itemsRef);
        console.log(`  ${categoryGroup} (${itemsSnapshot.docs.length} items)`);
      } catch (error) {
        console.log(`  ${categoryGroup} (unable to count items)`);
      }
    }
    
    console.log('-'.repeat(30));
    return categoryGroups;
    
  } catch (error) {
    console.error('Error listing category groups:', error.message);
    return [];
  }
}

// Main execution
async function main() {
  const categoryGroup = process.argv[2];
  
  if (!categoryGroup) {
    console.log('❓ USAGE: node download_products_by_category.js <categoryGroup>');
    console.log('');
    await listAvailableCategoryGroups();
    console.log('');
    console.log('📝 Example: node download_products_by_category.js bakeries_biscuits');
    process.exit(1);
  }
  
  if (categoryGroup === '--list' || categoryGroup === '-l') {
    await listAvailableCategoryGroups();
    process.exit(0);
  }
  
  try {
    await downloadProductsFromCategory(categoryGroup);
    process.exit(0);
  } catch (error) {
    console.error('💥 Script failed:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { downloadProductsFromCategory, listAvailableCategoryGroups };
