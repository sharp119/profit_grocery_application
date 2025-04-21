import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, doc, getDoc } from 'firebase/firestore';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs';

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

/**
 * Create a map of all products by ID
 */
async function getAllProducts() {
  console.log('Fetching all products...');
  
  const productMap = new Map();
  
  // List of all category groups
  const CATEGORY_GROUPS = [
    'bakeries_biscuits',
    'beauty_hygiene',
    'dairy_eggs',
    'fruits_vegetables',
    'grocery_kitchen',
    'snacks_drinks'
  ];
  
  for (const categoryGroup of CATEGORY_GROUPS) {
    try {
      // Get all items under this category
      const itemsSnapshot = await getDocs(collection(db, 'products', categoryGroup, 'items'));
      
      for (const itemDoc of itemsSnapshot.docs) {
        const categoryItem = itemDoc.id;
        
        // Get all products under this item
        const productsPath = `products/${categoryGroup}/items/${categoryItem}/products`;
        const productsSnapshot = await getDocs(collection(db, productsPath));
        
        for (const productDoc of productsSnapshot.docs) {
          const productData = productDoc.data();
          
          productMap.set(productDoc.id, {
            id: productDoc.id,
            name: productData.name || 'Unknown Product',
            price: productData.price || 0,
            path: `${productsPath}/${productDoc.id}`,
            categoryGroup,
            categoryItem
          });
        }
      }
    } catch (error) {
      console.error(`Error fetching products from ${categoryGroup}:`, error);
    }
  }
  
  console.log(`Found ${productMap.size} products in total.`);
  return productMap;
}

/**
 * Get all discounts from the discounts collection
 */
async function getAllDiscounts() {
  console.log('Fetching all discounts...');
  
  try {
    const discountsSnapshot = await getDocs(collection(db, 'discounts'));
    
    const discounts = [];
    
    for (const doc of discountsSnapshot.docs) {
      const data = doc.data();
      discounts.push({
        id: doc.id,
        ...data
      });
    }
    
    console.log(`Found ${discounts.length} discounts in total.`);
    return discounts;
  } catch (error) {
    console.error('Error fetching discounts:', error);
    return [];
  }
}

/**
 * Calculate the discounted price based on discount type and value
 */
function calculateDiscountedPrice(originalPrice, discountType, discountValue) {
  if (discountType === 'flat') {
    return Math.max(0, originalPrice - discountValue);
  } else if (discountType === 'percentage') {
    return originalPrice * (1 - discountValue / 100);
  }
  return originalPrice;
}

/**
 * Format currency for display
 */
function formatCurrency(value) {
  return `₹${value.toFixed(2)}`;
}

/**
 * Generate a Markdown filename with current date
 */
function getMarkdownFilename() {
  const now = new Date();
  const dateString = now.toISOString().split('T')[0]; // YYYY-MM-DD format
  return `discount_verification_${dateString}.md`;
}

/**
 * Format date for display
 */
function formatDate(date) {
  if (!date) return 'N/A';
  try {
    const d = date instanceof Date ? date : date.toDate();
    return d.toISOString().split('T')[0]; // YYYY-MM-DD
  } catch (error) {
    return 'Invalid Date';
  }
}

/**
 * Truncate string with ellipsis if too long
 */
function truncate(str, length = 20) {
  if (!str) return '';
  return str.length > length ? str.substring(0, length) + '...' : str;
}

/**
 * Write discount verification results to Markdown
 */
function exportToMarkdown(results, filename, summary) {
  console.log(`\nExporting results to Markdown file: ${filename}`);
  
  try {
    const now = new Date();
    const formattedDate = now.toISOString().split('T')[0];
    
    // Start building the markdown content with better formatting
    let mdContent = `# Discount Verification Report\n\n`;
    mdContent += `*Generated on: ${new Date().toLocaleDateString('en-US', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    })}*\n\n`;
    
    // Add summary badges at the top
    mdContent += `<div align="center">\n\n`;
    mdContent += `![Total](https://img.shields.io/badge/Total%20Discounts-${summary.total}-blue)\n`;
    mdContent += `![Valid](https://img.shields.io/badge/Valid-${summary.valid}-success)\n`;
    mdContent += `![Invalid](https://img.shields.io/badge/Invalid-${summary.invalid}-${summary.invalid > 0 ? 'critical' : 'success'})\n`;
    mdContent += `![Flat](https://img.shields.io/badge/Flat%20Discounts-${summary.flat}-orange)\n`;
    mdContent += `![Percentage](https://img.shields.io/badge/Percentage%20Discounts-${summary.percentage}-purple)\n\n`;
    mdContent += `</div>\n\n`;
    
    // Add summary section with better formatting
    mdContent += `## 📊 Summary\n\n`;
    
    // Create a nice summary table
    mdContent += `| Metric | Count | Percentage |\n`;
    mdContent += `| ------ | ----- | ---------- |\n`;
    mdContent += `| **Total Discounts** | ${summary.total} | 100% |\n`;
    mdContent += `| **✅ Valid Discounts** | ${summary.valid} | ${(summary.valid / summary.total * 100).toFixed(1)}% |\n`;
    mdContent += `| **❌ Invalid Discounts** | ${summary.invalid} | ${(summary.invalid / summary.total * 100).toFixed(1)}% |\n`;
    mdContent += `| **💰 Flat Discounts** | ${summary.flat} | ${(summary.flat / summary.total * 100).toFixed(1)}% |\n`;
    mdContent += `| **📊 Percentage Discounts** | ${summary.percentage} | ${(summary.percentage / summary.total * 100).toFixed(1)}% |\n\n`;
    
    // Add price distribution with better formatting
    mdContent += `### 💵 Price Distribution\n\n`;
    mdContent += `| Price Range | Product Count | Percentage |\n`;
    mdContent += `| ----------- | ------------- | ---------- |\n`;
    
    const totalProducts = Object.values(summary.priceRanges).reduce((a, b) => a + b, 0);
    
    for (const [range, count] of Object.entries(summary.priceRanges)) {
      mdContent += `| **${range}** | ${count} | ${(count / totalProducts * 100).toFixed(1)}% |\n`;
    }
    
    mdContent += `\n`;
    
    // Add high-priced products information with better formatting
    mdContent += `### 💎 High-Value Products\n\n`;
    mdContent += `| Metric | Count | Percentage |\n`;
    mdContent += `| ------ | ----- | ---------- |\n`;
    mdContent += `| **Products with price > ₹200** | ${summary.highPricedProducts} | ${(summary.highPricedProducts / totalProducts * 100).toFixed(1)}% |\n`;
    mdContent += `| **High-value products with discounts** | ${summary.highPricedWithDiscount} | ${(summary.highPricedWithDiscount / summary.highPricedProducts * 100).toFixed(1)}% of high-value products |\n\n`;
    
    // Pre-filter valid results before using them for calculations
    const validResults = results.filter(r => r.valid);
    
    // Add discount efficiency analysis
    mdContent += `## 🔍 Discount Efficiency Analysis\n\n`;
    
    // Calculate average metrics
    const averageSavings = validResults.reduce((sum, item) => sum + item.savings, 0) / validResults.length || 0;
    const averageSavingsPercentage = validResults.reduce((sum, item) => sum + item.savingsPercentage, 0) / validResults.length || 0;
    const maxSavings = Math.max(...validResults.map(item => item.savings), 0);
    const maxSavingsPercentage = Math.max(...validResults.map(item => item.savingsPercentage), 0);
    
    mdContent += `| Metric | Value |\n`;
    mdContent += `| ------ | ----- |\n`;
    mdContent += `| **Average Discount Amount** | ${formatCurrency(averageSavings)} |\n`;
    mdContent += `| **Average Discount Percentage** | ${typeof averageSavingsPercentage === 'number' ? averageSavingsPercentage.toFixed(1) : averageSavingsPercentage}% |\n`;
    mdContent += `| **Maximum Discount Amount** | ${formatCurrency(maxSavings)} |\n`;
    mdContent += `| **Maximum Discount Percentage** | ${typeof maxSavingsPercentage === 'number' ? maxSavingsPercentage.toFixed(1) : maxSavingsPercentage}% |\n\n`;
    
    // Add valid discounts section with better formatting
    if (validResults.length > 0) {
      mdContent += `## ✅ Valid Discounts (${validResults.length})\n\n`;
      
      // Include a mini chart of top discounted products
      mdContent += `### 🏆 Top 5 Highest Discount Products\n\n`;
      mdContent += `| Product | Original Price | Discount | Final Price | Savings |\n`;
      mdContent += `| ------- | -------------- | -------- | ----------- | ------- |\n`;
      
      // Sort by savings amount and get top 5
      const topSavingsProducts = [...validResults]
        .sort((a, b) => b.savings - a.savings)
        .slice(0, 5);
      
      for (const product of topSavingsProducts) {
        const discountText = product.discountType === 'flat' 
          ? `🏷️ Flat ${formatCurrency(product.discountValue)} off` 
          : `📊 ${product.discountValue}% off`;
          
        mdContent += `| **${truncate(product.productName, 25)}** | ${formatCurrency(product.originalPrice)} | ${discountText} | ${formatCurrency(product.discountedPrice)} | ${formatCurrency(product.savings)} (${typeof product.savingsPercentage === 'number' ? product.savingsPercentage.toFixed(1) : product.savingsPercentage}%) |\n`;
      }
      
      mdContent += `\n`;
      
      // Full table of valid discounts
      mdContent += `### 📋 All Valid Discounts\n\n`;
      mdContent += `<details>\n<summary>Click to expand all ${validResults.length} valid discounts</summary>\n\n`;
      mdContent += `| Product | Original Price | Discount | Final Price | Savings | Category |\n`;
      mdContent += `| ------- | -------------- | -------- | ----------- | ------- | -------- |\n`;
      
      for (const result of validResults) {
        const discountText = result.discountType === 'flat' 
          ? `🏷️ ${formatCurrency(result.discountValue)} off` 
          : `📊 ${result.discountValue}% off`;
        
        mdContent += `| **${truncate(result.productName, 25)}** | ${formatCurrency(result.originalPrice)} | ${discountText} | ${formatCurrency(result.discountedPrice)} | ${formatCurrency(result.savings)} (${typeof result.savingsPercentage === 'number' ? result.savingsPercentage.toFixed(1) : result.savingsPercentage}%) | ${truncate(result.category, 20)} |\n`;
      }
      
      mdContent += `\n</details>\n\n`;
    }
    
    // Add invalid discounts section with better formatting
    const invalidResults = results.filter(r => !r.valid);
    if (invalidResults.length > 0) {
      mdContent += `## ❌ Invalid Discounts (${invalidResults.length})\n\n`;
      mdContent += `These discounts reference products that don't exist in the database or have other issues.\n\n`;
      
      mdContent += `| Product ID | Discount Type | Discount Value | Issue |\n`;
      mdContent += `| ---------- | ------------- | -------------- | ----- |\n`;
      
      for (const result of invalidResults) {
        const discountText = result.discountType === 'flat' 
          ? `Flat ${result.discountValue}` 
          : (result.discountType === 'percentage' ? `${result.discountValue}%` : 'N/A');
          
        mdContent += `| \`${result.productId}\` | ${result.discountType || 'N/A'} | ${discountText} | Product not found |\n`;
      }
      
      mdContent += `\n`;
    }
    
    // Add detailed discount information by category with better formatting
    mdContent += `## 📂 Discount Distribution by Category\n\n`;
    
    // Group by category
    const categoryGroups = {};
    
    for (const result of validResults) {
      const category = result.category.split('/')[0]; // Get main category
      if (!categoryGroups[category]) {
        categoryGroups[category] = [];
      }
      categoryGroups[category].push(result);
    }
    
    // Add category distribution summary
    mdContent += `### Category Distribution\n\n`;
    mdContent += `| Category | Count | Percentage |\n`;
    mdContent += `| -------- | ----- | ---------- |\n`;
    
    for (const [category, items] of Object.entries(categoryGroups)) {
      const formattedCategory = category.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
        
      mdContent += `| **${formattedCategory}** | ${items.length} | ${(items.length / validResults.length * 100).toFixed(1)}% |\n`;
    }
    
    mdContent += `\n`;
    
    // Add each category section with better formatting
    for (const [category, items] of Object.entries(categoryGroups)) {
      const formattedCategory = category.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
        
      mdContent += `### ${formattedCategory} (${items.length})\n\n`;
      
      mdContent += `<details>\n<summary>Show ${items.length} items in ${formattedCategory}</summary>\n\n`;
      
      mdContent += `| Product | Original Price | Discount | Final Price | Savings | Valid Until |\n`;
      mdContent += `| ------- | -------------- | -------- | ----------- | ------- | ----------- |\n`;
      
      for (const item of items) {
        const discountText = item.discountType === 'flat' 
          ? `🏷️ ${formatCurrency(item.discountValue)} off` 
          : `📊 ${item.discountValue}% off`;
        
        mdContent += `| **${truncate(item.productName, 25)}** | ${formatCurrency(item.originalPrice)} | ${discountText} | ${formatCurrency(item.discountedPrice)} | ${formatCurrency(item.savings)} (${typeof item.savingsPercentage === 'number' ? item.savingsPercentage.toFixed(1) : item.savingsPercentage}%) | ${formatDate(item.endDate)} |\n`;
      }
      
      mdContent += `\n</details>\n\n`;
    }
    
    // Add recommendations section
    mdContent += `## 📝 Recommendations\n\n`;
    
    if (invalidResults.length > 0) {
      mdContent += `- 🔍 Investigate the ${invalidResults.length} invalid discounts that reference non-existent products\n`;
      mdContent += `- 🗑️ Consider removing invalid discount entries\n`;
    } else {
      mdContent += `- ✅ All discounts are valid and reference existing products!\n`;
    }
    
    mdContent += `- 📊 Consider ${summary.percentage > summary.flat ? 'increasing' : 'decreasing'} the ratio of percentage vs. flat discounts\n`;
    mdContent += `- 💰 Review high-value products (>₹200) to ensure appropriate discount strategies\n`;
    mdContent += `- 🔄 Run this verification regularly to ensure data integrity\n\n`;
    
    // Add footer
    mdContent += `---\n\n`;
    mdContent += `<div align="center">\n\n`;
    mdContent += `*Generated by the Profit Grocery Verification System on ${formattedDate}*\n\n`;
    mdContent += `</div>`;
    
    // Write to file
    fs.writeFileSync(filename, mdContent);
    console.log(`Beautiful Markdown report exported successfully to ${filename}`);
    return true;
  } catch (error) {
    console.error('Error exporting to Markdown:', error);
    return false;
  }
}

/**
 * Verify discounts and display details
 */
async function verifyDiscounts() {
  console.log('Starting discount verification...');
  
  try {
    // Step 1: Get all products
    const productMap = await getAllProducts();
    
    // Step 2: Get all discounts
    const discounts = await getAllDiscounts();
    
    // Step 3: Match discounts with products and calculate discounted prices
    console.log('\n=== DISCOUNT VERIFICATION RESULTS ===');
    console.log('ID | Product Name | Original Price | Discount | Discounted Price | Category');
    console.log('-'.repeat(100));
    
    let validCount = 0;
    let invalidCount = 0;
    let flatCount = 0;
    let percentageCount = 0;
    
    // Prepare array to collect results for Markdown export
    const resultsForExport = [];
    
    for (const discount of discounts) {
      const product = productMap.get(discount.id);
      
      let resultRecord = {
        productId: discount.id,
        discountType: discount.discountType,
        discountValue: discount.discountValue,
        startDate: discount.startTimestamp?.toDate ? discount.startTimestamp.toDate() : null,
        endDate: discount.endTimestamp?.toDate ? discount.endTimestamp.toDate() : null,
        valid: false
      };
      
      if (!product) {
        console.log(`❌ INVALID: Discount ${discount.id} references a non-existent product.`);
        invalidCount++;
        resultsForExport.push(resultRecord);
        continue;
      }
      
      // Count discount types
      if (discount.discountType === 'flat') {
        flatCount++;
      } else if (discount.discountType === 'percentage') {
        percentageCount++;
      }
      
      // Calculate discounted price
      const originalPrice = product.price;
      const discountedPrice = calculateDiscountedPrice(
        originalPrice, 
        discount.discountType, 
        discount.discountValue
      );
      const savings = originalPrice - discountedPrice;
      const savingsPercentage = (savings / originalPrice) * 100;
      
      // Format discount text
      let discountText = '';
      if (discount.discountType === 'flat') {
        discountText = `Flat ${formatCurrency(discount.discountValue)} off`;
      } else if (discount.discountType === 'percentage') {
        discountText = `${discount.discountValue}% off`;
      }
      
      // Display the result
      console.log(`✅ ${discount.id.substring(0, 8)}... | ${product.name.substring(0, 20).padEnd(20)} | ${formatCurrency(originalPrice).padEnd(14)} | ${discountText.padEnd(10)} | ${formatCurrency(discountedPrice).padEnd(15)} | ${product.categoryGroup}/${product.categoryItem}`);
      console.log(`   Savings: ${formatCurrency(savings)} (${typeof savingsPercentage === 'number' ? savingsPercentage.toFixed(1) : savingsPercentage}%)`);
      console.log('-'.repeat(100));
      
      // Add to export records
      resultRecord = {
        ...resultRecord,
        productName: product.name,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        savings: savings,
        savingsPercentage: savingsPercentage,
        category: `${product.categoryGroup}/${product.categoryItem}`,
        valid: true
      };
      resultsForExport.push(resultRecord);
      
      validCount++;
    }
    
    // Step 4: Collect data for summary
    const summary = {
      total: discounts.length,
      valid: validCount,
      invalid: invalidCount,
      flat: flatCount,
      percentage: percentageCount
    };
    
    // Step 5: Check for discounts on high-priced items
    const highPricedProducts = Array.from(productMap.values())
      .filter(product => product.price > 200);
    
    const highPricedWithDiscount = highPricedProducts
      .filter(product => discounts.some(d => d.id === product.id));
    
    summary.highPricedProducts = highPricedProducts.length;
    summary.highPricedWithDiscount = highPricedWithDiscount.length;
    
    console.log('\n=== SUMMARY ===');
    console.log(`Total discounts: ${discounts.length}`);
    console.log(`Valid discounts: ${validCount}`);
    console.log(`Invalid discounts: ${invalidCount}`);
    console.log(`Flat discounts: ${flatCount}`);
    console.log(`Percentage discounts: ${percentageCount}`);
    console.log(`\nProducts with price > 200: ${highPricedProducts.length}`);
    console.log(`Products with price > 200 and discount: ${highPricedWithDiscount.length}`);
    
    // Step 6: Check for price distribution
    const priceRanges = {
      '0-50': 0,
      '51-100': 0,
      '101-200': 0,
      '201-500': 0,
      '>500': 0
    };
    
    for (const product of productMap.values()) {
      if (product.price <= 50) priceRanges['0-50']++;
      else if (product.price <= 100) priceRanges['51-100']++;
      else if (product.price <= 200) priceRanges['101-200']++;
      else if (product.price <= 500) priceRanges['201-500']++;
      else priceRanges['>500']++;
    }
    
    summary.priceRanges = priceRanges;
    
    console.log('\nPrice distribution of all products:');
    for (const [range, count] of Object.entries(priceRanges)) {
      console.log(`  ${range}: ${count} products`);
    }
    
    // Step 7: Export results to Markdown
    const mdFilename = getMarkdownFilename();
    exportToMarkdown(resultsForExport, mdFilename, summary);
    
  } catch (error) {
    console.error('Error during discount verification:', error);
  }
}

// Execute the script if run directly
if (isMainModule) {
  verifyDiscounts()
    .then(() => {
      console.log('\nVerification complete.');
      process.exit(0);
    })
    .catch(error => {
      console.error('Verification failed:', error);
      process.exit(1);
    });
} 