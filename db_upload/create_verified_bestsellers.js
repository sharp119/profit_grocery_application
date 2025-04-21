import { initializeApp } from 'firebase/app';
import { 
  getFirestore, 
  collection, 
  getDocs, 
  doc, 
  setDoc, 
  deleteDoc, 
  query,
  where,
  getDoc,
  limit
} from 'firebase/firestore';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';
import * as fs from 'fs';

// ES modules equivalent for the require.main === module pattern
const __filename = fileURLToPath(import.meta.url);
const isMainModule = process.argv[1] === __filename;

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

// Configuration
const FLAT_DISCOUNT_COUNT = 6;
const PERCENTAGE_DISCOUNT_COUNT = 6;
const REGULAR_PRODUCTS_COUNT = 8;
const TOTAL_BESTSELLERS = FLAT_DISCOUNT_COUNT + PERCENTAGE_DISCOUNT_COUNT + REGULAR_PRODUCTS_COUNT;

// List of all category groups to search for products
const CATEGORY_GROUPS = [
  'bakeries_biscuits',
  'beauty_hygiene',
  'dairy_eggs',
  'fruits_vegetables',
  'grocery_kitchen',
  'snacks_drinks'
];

/**
 * Get discounts with flat type
 */
async function getFlatDiscounts() {
  console.log(`\nFetching ${FLAT_DISCOUNT_COUNT} flat discounts...`);
  const flatDiscounts = [];
  
  try {
    const discountsQuery = query(collection(db, 'discounts'), where('discountType', '==', 'flat'), limit(50));
    const discountsSnapshot = await getDocs(discountsQuery);
    
    console.log("\n=== FLAT DISCOUNTS ===");
    
    let count = 0;
    for (const discountDoc of discountsSnapshot.docs) {
      if (count >= FLAT_DISCOUNT_COUNT) break;
      
      const productId = discountDoc.id;
      const discountData = discountDoc.data();
      const discountValue = discountData.discountValue;
      
      flatDiscounts.push({
        id: productId,
        value: discountValue,
        type: 'flat'
      });
      
      console.log(`Discount ID: ${productId} | Value: ₹${discountValue} off`);
      count++;
    }
    
    console.log(`\nFound ${flatDiscounts.length} flat discounts`);
    return flatDiscounts;
  } catch (error) {
    console.error('Error fetching flat discounts:', error);
    return [];
  }
}

/**
 * Get discounts with percentage type
 */
async function getPercentageDiscounts() {
  console.log(`\nFetching ${PERCENTAGE_DISCOUNT_COUNT} percentage discounts...`);
  const percentageDiscounts = [];
  
  try {
    const discountsQuery = query(collection(db, 'discounts'), where('discountType', '==', 'percentage'), limit(50));
    const discountsSnapshot = await getDocs(discountsQuery);
    
    console.log("\n=== PERCENTAGE DISCOUNTS ===");
    
    let count = 0;
    for (const discountDoc of discountsSnapshot.docs) {
      if (count >= PERCENTAGE_DISCOUNT_COUNT) break;
      
      const productId = discountDoc.id;
      const discountData = discountDoc.data();
      const discountValue = discountData.discountValue;
      
      percentageDiscounts.push({
        id: productId,
        value: discountValue,
        type: 'percentage'
      });
      
      console.log(`Discount ID: ${productId} | Value: ${discountValue}% off`);
      count++;
    }
    
    console.log(`\nFound ${percentageDiscounts.length} percentage discounts`);
    return percentageDiscounts;
  } catch (error) {
    console.error('Error fetching percentage discounts:', error);
    return [];
  }
}

/**
 * Get regular products (without discounts)
 */
async function getRegularProducts(usedProductIds) {
  console.log(`\nFetching ${REGULAR_PRODUCTS_COUNT} regular products...`);
  const regularProducts = [];
  
  try {
    console.log("\n=== REGULAR PRODUCTS ===");
    
    // For each category group
    for (const categoryGroup of CATEGORY_GROUPS) {
      if (regularProducts.length >= REGULAR_PRODUCTS_COUNT) break;
      
      try {
        // Get all items under this category
        const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
        
        // For each item in the category group
        for (const itemDoc of itemsSnapshot.docs) {
          if (regularProducts.length >= REGULAR_PRODUCTS_COUNT) break;
          
          const categoryItem = itemDoc.id;
          
          // Get all products under this item
          const productsPath = `products/${categoryGroup}/items/${categoryItem}/products`;
          const productsSnapshot = await getDocs(collection(db, productsPath));
          
          // For each product
          for (const productDoc of productsSnapshot.docs) {
            if (regularProducts.length >= REGULAR_PRODUCTS_COUNT) break;
            
            const productId = productDoc.id;
            
            // Skip products that are already in used product IDs
            if (usedProductIds.includes(productId)) {
              continue;
            }
            
            const productData = productDoc.data();
            
            regularProducts.push({
              id: productId,
              name: productData.name || 'Unknown Product',
              price: productData.price || 0,
              categoryGroup,
              categoryItem,
              type: 'none',
              value: 0
            });
            
            console.log(`Product ID: ${productId} | Name: ${productData.name || 'Unknown'} | Category: ${categoryGroup}/${categoryItem}`);
          }
        }
      } catch (error) {
        console.error(`Error fetching products from ${categoryGroup}:`, error);
      }
    }
    
    console.log(`\nFound ${regularProducts.length} regular products`);
    return regularProducts;
  } catch (error) {
    console.error('Error fetching regular products:', error);
    return [];
  }
}

/**
 * Shuffle array using Fisher-Yates algorithm
 */
function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

/**
 * Create bestsellers with randomly assigned ranks
 */
async function createBestsellers(flatDiscounts, percentageDiscounts, regularProducts) {
  console.log('\nCreating bestsellers with randomized ranks...');
  
  try {
    // Clear existing bestsellers first
    await clearExistingBestsellers();
    
    // Combine all products into a single array
    const allProducts = [
      ...flatDiscounts.map(p => ({
        id: p.id,
        discountType: 'flat',
        discountValue: p.value,
        productType: 'Flat discount'
      })),
      ...percentageDiscounts.map(p => ({
        id: p.id,
        discountType: 'percentage',
        discountValue: p.value,
        productType: 'Percentage discount'
      })),
      ...regularProducts.map(p => ({
        id: p.id,
        discountType: 'none',
        discountValue: 0,
        name: p.name,
        productType: 'Regular product'
      }))
    ];
    
    // Shuffle the array to randomize the order
    const shuffledProducts = shuffleArray(allProducts);
    
    // Create bestsellers with randomized ranks
    for (let i = 0; i < shuffledProducts.length; i++) {
      const product = shuffledProducts[i];
      const rank = i + 1;
      
      await setDoc(doc(db, 'bestsellers', product.id), { 
        rank: rank,
        discountType: product.discountType,
        discountValue: product.discountValue
      });
      
      const productInfo = product.name 
        ? `${product.name} - ${product.productType}`
        : product.productType;
      
      console.log(`Created bestseller rank #${rank}: ${product.id} (${productInfo})`);
    }
    
    // Print distribution summary
    console.log(`\nCreated ${shuffledProducts.length} bestsellers with randomized ranks:`);
    console.log(`- ${flatDiscounts.length} with flat discounts`);
    console.log(`- ${percentageDiscounts.length} with percentage discounts`);
    console.log(`- ${regularProducts.length} regular products`);
    
    // Print the final bestseller ranks for verification
    console.log('\n=== FINAL BESTSELLER RANKS ===');
    
    const flatDiscountIds = new Set(flatDiscounts.map(p => p.id));
    const percentageDiscountIds = new Set(percentageDiscounts.map(p => p.id));
    
    for (let i = 0; i < shuffledProducts.length; i++) {
      const product = shuffledProducts[i];
      const rank = i + 1;
      let type = '';
      
      if (flatDiscountIds.has(product.id)) {
        type = 'Flat discount';
      } else if (percentageDiscountIds.has(product.id)) {
        type = 'Percentage discount';
      } else {
        type = 'Regular product';
      }
      
      console.log(`Rank #${rank}: ${product.id} (${type})`);
    }
    
  } catch (error) {
    console.error('Error creating bestsellers:', error);
  }
}

/**
 * Clear existing bestsellers in the collection
 */
async function clearExistingBestsellers() {
  console.log('Clearing existing bestsellers...');
  
  try {
    const bestsellersSnapshot = await getDocs(collection(db, 'bestsellers'));
    
    let deletedCount = 0;
    for (const bestsellerDoc of bestsellersSnapshot.docs) {
      await deleteDoc(doc(db, 'bestsellers', bestsellerDoc.id));
      deletedCount++;
    }
    
    console.log(`Cleared ${deletedCount} existing bestsellers.`);
  } catch (error) {
    console.error('Error clearing existing bestsellers:', error);
  }
}

/**
 * Verify bestsellers by checking if they exist in the products collection
 * and retrieving their names
 */
async function verifyBestsellers() {
  console.log('\n=== VERIFYING BESTSELLERS ===');
  console.log('Checking if bestseller IDs exist in the products collection...');
  
  try {
    // Get all bestsellers
    const bestsellersSnapshot = await getDocs(collection(db, 'bestsellers'));
    
    if (bestsellersSnapshot.empty) {
      console.log('No bestsellers found to verify.');
      return;
    }
    
    console.log(`Found ${bestsellersSnapshot.size} bestsellers to verify.`);
    
    // Create arrays to track verification results
    const verified = [];
    const notFound = [];
    
    // Check each bestseller
    for (const bestsellerDoc of bestsellersSnapshot.docs) {
      const bestsellerId = bestsellerDoc.id;
      const bestsellerData = bestsellerDoc.data();
      const rank = bestsellerData.rank;
      let productName = null;
      let found = false;
      
      // Search across all category groups
      for (const categoryGroup of CATEGORY_GROUPS) {
        if (found) break;
        
        try {
          // Get all items under this category
          const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
          
          // Search through each item
          for (const itemDoc of itemsSnapshot.docs) {
            if (found) break;
            
            const categoryItem = itemDoc.id;
            const productsPath = `products/${categoryGroup}/items/${categoryItem}/products`;
            
            // Try to get the product directly
            const productRef = doc(db, productsPath, bestsellerId);
            const productSnapshot = await getDoc(productRef);
            
            if (productSnapshot.exists()) {
              const productData = productSnapshot.data();
              productName = productData.name || 'Unnamed Product';
              found = true;
              
              // Add category information to the verified object
              verified.push({
                id: bestsellerId,
                rank,
                name: productName,
                category: `${categoryGroup}/${categoryItem}`,
                price: productData.price || 0,
                discountType: bestsellerData.discountType || 'none',
                discountValue: bestsellerData.discountValue || 0
              });
              
              break;
            }
          }
        } catch (error) {
          console.error(`Error searching for product in ${categoryGroup}:`, error);
        }
      }
      
      // If product wasn't found in any category
      if (!found) {
        notFound.push({
          id: bestsellerId,
          rank
        });
      }
    }
    
    // Display verification results
    console.log(`\nVerification complete: ${verified.length} verified, ${notFound.length} not found`);
    
    if (verified.length > 0) {
      console.log('\n=== VERIFIED BESTSELLERS ===');
      console.log('| Rank | Bestseller ID | Product Name | Discount Type | Discount Value |');
      console.log('|------|--------------|--------------|---------------|----------------|');
      
      // Sort by rank
      verified.sort((a, b) => a.rank - b.rank);
      
      for (const item of verified) {
        let discountInfo = item.discountType === 'none' 
          ? 'None' 
          : (item.discountType === 'flat' 
              ? `Flat ₹${item.discountValue} off` 
              : `${item.discountValue}% off`);
              
        console.log(`| ${item.rank} | ${item.id} | ${item.name} | ${item.discountType} | ${discountInfo} |`);
      }
    }
    
    if (notFound.length > 0) {
      console.log('\n=== BESTSELLERS NOT FOUND IN PRODUCTS ===');
      console.log('| Rank | Bestseller ID |');
      console.log('|------|--------------|');
      
      // Sort by rank
      notFound.sort((a, b) => a.rank - b.rank);
      
      for (const item of notFound) {
        console.log(`| ${item.rank} | ${item.id} |`);
      }
    }
    
    // Create a beautiful verification report in Markdown
    const reportDate = new Date().toISOString().split('T')[0];
    const reportFileName = `bestsellers_verification_${reportDate}.md`;
    
    // Calculate some stats for the report
    const discountStats = {
      flat: verified.filter(item => item.discountType === 'flat').length,
      percentage: verified.filter(item => item.discountType === 'percentage').length,
      none: verified.filter(item => item.discountType === 'none').length
    };
    
    // Categories with bestsellers
    const categoryCounts = {};
    for (const item of verified) {
      const categoryGroup = item.category.split('/')[0];
      categoryCounts[categoryGroup] = (categoryCounts[categoryGroup] || 0) + 1;
    }
    
    // Create a beautiful Markdown report
    let markdownReport = `# Bestseller Verification Report\n\n`;
    markdownReport += `*Generated on: ${new Date().toLocaleDateString('en-US', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    })}*\n\n`;
    
    // Add summary badges at the top
    markdownReport += `<div align="center">\n\n`;
    markdownReport += `![Total](https://img.shields.io/badge/Total%20Bestsellers-${bestsellersSnapshot.size}-blue)\n`;
    markdownReport += `![Verified](https://img.shields.io/badge/Verified-${verified.length}-success)\n`;
    markdownReport += `![Not Found](https://img.shields.io/badge/Not%20Found-${notFound.length}-${notFound.length > 0 ? 'critical' : 'success'})\n\n`;
    markdownReport += `</div>\n\n`;
    
    // Add summary section
    markdownReport += `## 📊 Summary\n\n`;
    
    // Create a nice summary table
    markdownReport += `| Metric | Count | Percentage |\n`;
    markdownReport += `| ------ | ----- | ---------- |\n`;
    markdownReport += `| **Total Bestsellers** | ${bestsellersSnapshot.size} | 100% |\n`;
    markdownReport += `| **✅ Verified Products** | ${verified.length} | ${(verified.length / bestsellersSnapshot.size * 100).toFixed(1)}% |\n`;
    markdownReport += `| **❌ Not Found** | ${notFound.length} | ${(notFound.length / bestsellersSnapshot.size * 100).toFixed(1)}% |\n`;
    markdownReport += `| **💰 With Flat Discounts** | ${discountStats.flat} | ${(discountStats.flat / bestsellersSnapshot.size * 100).toFixed(1)}% |\n`;
    markdownReport += `| **📊 With Percentage Discounts** | ${discountStats.percentage} | ${(discountStats.percentage / bestsellersSnapshot.size * 100).toFixed(1)}% |\n`;
    markdownReport += `| **🏷️ Without Discounts** | ${discountStats.none} | ${(discountStats.none / bestsellersSnapshot.size * 100).toFixed(1)}% |\n\n`;
    
    // Add distribution by category
    if (Object.keys(categoryCounts).length > 0) {
      markdownReport += `## 📂 Distribution by Category\n\n`;
      markdownReport += `| Category | Count | Percentage |\n`;
      markdownReport += `| -------- | ----- | ---------- |\n`;
      
      for (const [category, count] of Object.entries(categoryCounts)) {
        const formattedCategory = category.split('_')
          .map(word => word.charAt(0).toUpperCase() + word.slice(1))
          .join(' ');
          
        markdownReport += `| **${formattedCategory}** | ${count} | ${(count / verified.length * 100).toFixed(1)}% |\n`;
      }
      
      markdownReport += `\n`;
    }
    
    // Add verified bestsellers section
    if (verified.length > 0) {
      markdownReport += `## ✅ Verified Bestsellers (${verified.length})\n\n`;
      
      // Create a table with all verified bestsellers
      markdownReport += `| Rank | Product ID | Product Name | Category | Price | Discount |\n`;
      markdownReport += `| ---- | ---------- | ------------ | -------- | ----- | -------- |\n`;
      
      for (const item of verified) {
        const categoryPath = item.category.split('/');
        const formattedCategory = categoryPath[0].split('_')
          .map(word => word.charAt(0).toUpperCase() + word.slice(1))
          .join(' ');
          
        const itemCategory = `${formattedCategory} > ${categoryPath[1]}`;
        
        let discountInfo = '—';
        if (item.discountType === 'flat') {
          discountInfo = `🏷️ Flat ₹${item.discountValue} off`;
        } else if (item.discountType === 'percentage') {
          discountInfo = `📊 ${item.discountValue}% off`;
        }
        
        markdownReport += `| **#${item.rank}** | \`${item.id}\` | **${item.name}** | ${itemCategory} | ₹${item.price.toFixed(2)} | ${discountInfo} |\n`;
      }
      
      markdownReport += `\n`;
    }
    
    // Add not found section
    if (notFound.length > 0) {
      markdownReport += `## ❌ Bestsellers Not Found (${notFound.length})\n\n`;
      markdownReport += `These bestseller IDs could not be found in the products collection. They may be invalid or deleted products.\n\n`;
      
      markdownReport += `| Rank | Bestseller ID |\n`;
      markdownReport += `| ---- | ------------ |\n`;
      
      for (const item of notFound) {
        markdownReport += `| **#${item.rank}** | \`${item.id}\` |\n`;
      }
      
      markdownReport += `\n`;
    }
    
    // Add recommendations section
    markdownReport += `## 📝 Recommendations\n\n`;
    
    if (notFound.length > 0) {
      markdownReport += `- 🔍 Investigate the ${notFound.length} bestsellers that were not found in the products collection\n`;
      markdownReport += `- 🗑️ Consider removing invalid bestseller entries\n`;
    } else {
      markdownReport += `- ✅ All bestsellers were verified successfully!\n`;
    }
    
    markdownReport += `- 📊 Review the distribution of discounted vs. non-discounted bestsellers\n`;
    markdownReport += `- 🔄 Run this verification regularly to ensure data integrity\n\n`;
    
    // Add footer
    markdownReport += `---\n\n`;
    markdownReport += `<div align="center">\n\n`;
    markdownReport += `*Generated by the Profit Grocery Verification System on ${reportDate}*\n\n`;
    markdownReport += `</div>`;
    
    // Write the report to a file
    fs.writeFileSync(reportFileName, markdownReport);
    console.log(`\nBeautiful verification report saved to ${reportFileName}`);
    
  } catch (error) {
    console.error('Error verifying bestsellers:', error);
  }
}

/**
 * Main function to display discounts and create bestsellers
 */
async function displayDiscountsAndCreateBestsellers() {
  console.log('Starting bestseller creation with randomized ranks...');
  
  // Step 1: Get flat discounts
  const flatDiscounts = await getFlatDiscounts();
  
  // Step 2: Get percentage discounts
  const percentageDiscounts = await getPercentageDiscounts();
  
  // Step 3: Get the discount product IDs to avoid duplicates
  const usedProductIds = [
    ...flatDiscounts.map(d => d.id),
    ...percentageDiscounts.map(d => d.id)
  ];
  
  // Step 4: Get regular products, excluding the discount products
  const regularProducts = await getRegularProducts(usedProductIds);
  
  // Step 5: Create bestsellers using all these products with randomized ranks
  await createBestsellers(flatDiscounts, percentageDiscounts, regularProducts);
  
  // Step 6: Verify the bestsellers
  await verifyBestsellers();
  
  console.log('\nProcess completed successfully.');
  console.log(`Created ${TOTAL_BESTSELLERS} bestsellers with randomized ranks.`);
}

// Parse command line arguments
const args = process.argv.slice(2);
const command = args[0];

// Execute the appropriate command
if (isMainModule) {
  if (command === 'verify') {
    // Only run verification
    verifyBestsellers()
      .then(() => {
        console.log('\nVerification completed.');
        process.exit(0);
      })
      .catch(error => {
        console.error('Verification failed:', error);
        process.exit(1);
      });
  } else {
    // Run the full process
    displayDiscountsAndCreateBestsellers()
      .then(() => {
        console.log('\nScript execution completed.');
        process.exit(0);
      })
      .catch(error => {
        console.error('Script failed:', error);
        process.exit(1);
      });
  }
} 