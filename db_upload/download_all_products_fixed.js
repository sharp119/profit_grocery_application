import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

console.log('🚀 FIRESTORE PRODUCTS DOWNLOAD SCRIPT');
console.log('🔧 Initializing...');

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

// Helper function to create a delay
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Function to download all products from a specific category item
async function downloadProductsFromCategoryItem(categoryGroup, categoryItem) {
  try {
    console.log(`    📦 Downloading products from ${categoryGroup}/${categoryItem}...`);
    
    const productsRef = collection(db, 'products', categoryGroup, 'items', categoryItem, 'products');
    const productsSnapshot = await getDocs(productsRef);
    
    const products = [];
    
    productsSnapshot.forEach((productDoc) => {
      const productData = productDoc.data();
      
      // Add the document ID and clean up the data
      const product = {
        id: productDoc.id,
        ...productData,
        // Convert Firestore timestamps to ISO strings if they exist
        createdAt: productData.createdAt?.toDate?.()?.toISOString() || productData.createdAt,
        updatedAt: productData.updatedAt?.toDate?.()?.toISOString() || productData.updatedAt
      };
      
      products.push(product);
    });
    
    console.log(`      ✅ Found ${products.length} products in ${categoryGroup}/${categoryItem}`);
    return products;
    
  } catch (error) {
    console.error(`      ❌ Error downloading products from ${categoryGroup}/${categoryItem}:`, error.message);
    return [];
  }
}

// Function to download all category items from a category group
async function downloadProductsFromCategoryGroup(categoryGroup) {
  try {
    console.log(`  📁 Processing category group: ${categoryGroup}`);
    
    const itemsRef = collection(db, 'products', categoryGroup, 'items');
    const itemsSnapshot = await getDocs(itemsRef);
    
    const categoryItems = {};
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      
      // Download products from this category item
      const products = await downloadProductsFromCategoryItem(categoryGroup, categoryItem);
      
      if (products.length > 0) {
        categoryItems[categoryItem] = products;
      }
      
      // Add a small delay to avoid overwhelming Firestore
      await delay(100);
    }
    
    const totalProducts = Object.values(categoryItems).reduce((sum, products) => sum + products.length, 0);
    console.log(`  ✅ Downloaded ${totalProducts} products from ${categoryGroup}`);
    
    return categoryItems;
    
  } catch (error) {
    console.error(`  ❌ Error processing category group ${categoryGroup}:`, error.message);
    return {};
  }
}

// Main function to download all products
async function downloadAllProducts() {
  console.log('\\n🚀 Starting to download all products from Firestore...');
  console.log('=' .repeat(60));
  
  const startTime = Date.now();
  let totalProductsDownloaded = 0;
  
  try {
    // Get all category groups from the products collection
    console.log('📂 Fetching category groups...');
    const productsRef = collection(db, 'products');
    const categoryGroupsSnapshot = await getDocs(productsRef);
    
    console.log(`📂 Found ${categoryGroupsSnapshot.docs.length} category groups`);
    
    const allProducts = {};
    
    for (const categoryGroupDoc of categoryGroupsSnapshot.docs) {
      const categoryGroup = categoryGroupDoc.id;
      
      // Download all products from this category group
      const categoryProducts = await downloadProductsFromCategoryGroup(categoryGroup);
      
      if (Object.keys(categoryProducts).length > 0) {
        allProducts[categoryGroup] = categoryProducts;
        
        // Count total products in this category group
        const categoryTotal = Object.values(categoryProducts).reduce((sum, products) => sum + products.length, 0);
        totalProductsDownloaded += categoryTotal;
      }
      
      // Add a small delay between category groups
      await delay(200);
    }
    
    // Create the final export object with metadata
    const exportData = {
      metadata: {
        exportDate: new Date().toISOString(),
        totalCategoryGroups: Object.keys(allProducts).length,
        totalCategoryItems: Object.values(allProducts).reduce((sum, group) => sum + Object.keys(group).length, 0),
        totalProducts: totalProductsDownloaded,
        exportDurationMs: Date.now() - startTime,
        firebaseProject: process.env.FIREBASE_PROJECT_ID
      },
      products: allProducts
    };
    
    // Generate filename with timestamp
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `firestore_products_export_${timestamp}.json`;
    const filepath = path.join(process.cwd(), filename);
    
    // Save to JSON file with pretty formatting
    console.log(`\\n💾 Saving JSON export to: ${filename}`);
    fs.writeFileSync(filepath, JSON.stringify(exportData, null, 2), 'utf8');
    
    // Create a summary file
    const summaryFilename = `firestore_products_summary_${timestamp}.txt`;
    const summaryFilepath = path.join(process.cwd(), summaryFilename);
    
    let summary = `FIRESTORE PRODUCTS EXPORT SUMMARY\\n`;
    summary += `${'='.repeat(50)}\\n\\n`;
    summary += `Export Date: ${exportData.metadata.exportDate}\\n`;
    summary += `Firebase Project: ${process.env.FIREBASE_PROJECT_ID}\\n`;
    summary += `Total Products Downloaded: ${totalProductsDownloaded}\\n`;
    summary += `Total Category Groups: ${Object.keys(allProducts).length}\\n`;
    summary += `Total Category Items: ${Object.values(allProducts).reduce((sum, group) => sum + Object.keys(group).length, 0)}\\n`;
    summary += `Export Duration: ${(Date.now() - startTime) / 1000} seconds\\n\\n`;
    
    summary += `BREAKDOWN BY CATEGORY GROUP:\\n`;
    summary += `${'-'.repeat(30)}\\n`;
    
    Object.entries(allProducts).forEach(([categoryGroup, categoryItems]) => {
      const groupTotal = Object.values(categoryItems).reduce((sum, products) => sum + products.length, 0);
      summary += `${categoryGroup}: ${groupTotal} products\\n`;
      
      Object.entries(categoryItems).forEach(([categoryItem, products]) => {
        summary += `  └─ ${categoryItem}: ${products.length} products\\n`;
      });
      summary += '\\n';
    });
    
    console.log(`📄 Saving summary to: ${summaryFilename}`);
    fs.writeFileSync(summaryFilepath, summary, 'utf8');
    
    console.log('\\n' + '='.repeat(60));
    console.log('🎉 EXPORT COMPLETED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log(`📊 Total Products Downloaded: ${totalProductsDownloaded}`);
    console.log(`📁 Total Category Groups: ${Object.keys(allProducts).length}`);
    console.log(`📋 Total Category Items: ${Object.values(allProducts).reduce((sum, group) => sum + Object.keys(group).length, 0)}`);
    console.log(`⏱️  Export Duration: ${(Date.now() - startTime) / 1000} seconds`);
    console.log(`💾 JSON Export saved to: ${filename}`);
    console.log(`📄 Summary saved to: ${summaryFilename}`);
    console.log('='.repeat(60));
    
    return exportData;
    
  } catch (error) {
    console.error('\\n❌ EXPORT FAILED:');
    console.error('Error Message:', error.message);
    console.error('Error Code:', error.code || 'N/A');
    console.error('Full Error:', error);
    throw error;
  }
}

// Execute the download immediately
console.log('🏃 Starting download process...');

downloadAllProducts()
  .then((result) => {
    console.log('\\n✅ Script completed successfully');
    console.log(`🎯 Total products exported: ${result.metadata.totalProducts}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error('\\n💥 Script failed with error:', error.message);
    console.error('💡 Check the error details above for troubleshooting');
    process.exit(1);
  });
