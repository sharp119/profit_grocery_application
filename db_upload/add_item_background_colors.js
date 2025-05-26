import fs from 'fs';
import path from 'path';

console.log('🎨 PRODUCT ITEM BACKGROUND COLOR ENHANCEMENT');
console.log('📋 Adding itemBackgroundColor to each product based on category...');
console.log('='.repeat(60));

// File paths - will look for the most recent enhanced file or fall back to original
const PROJECT_ROOT = 'F:\\Soup\\projects\\profit_grocery_application';

// Category to itemBackgroundColor mapping from your Firestore screenshots
const CATEGORY_BACKGROUND_COLORS = {
  'snacks_drinks': 4292998654,
  'grocery_kitchen': 4292998633,
  'fruits_vegetables': 4293457385,
  'bakeries_biscuits': 4294962355
};

function findLatestProductsFile() {
  console.log('🔍 Looking for products file...');
  
  // First, try to find the most recent enhanced file
  try {
    const files = fs.readdirSync(PROJECT_ROOT);
    const enhancedFiles = files.filter(file => file.startsWith('enhanced_products_') && file.endsWith('.json'));
    
    if (enhancedFiles.length > 0) {
      // Sort by filename (which includes timestamp) to get the latest
      const latestEnhanced = enhancedFiles.sort().reverse()[0];
      const latestPath = path.join(PROJECT_ROOT, latestEnhanced);
      console.log(`✅ Found latest enhanced file: ${latestEnhanced}`);
      return latestPath;
    }
  } catch (error) {
    console.log('⚠️  No enhanced files found, checking for flattened_products.json');
  }
  
  // Fall back to original flattened file
  const flattendPath = path.join(PROJECT_ROOT, 'flattened_products.json');
  if (fs.existsSync(flattendPath)) {
    console.log('✅ Using original flattened_products.json');
    return flattendPath;
  }
  
  console.error('❌ No products file found!');
  console.error('Please ensure one of these files exists:');
  console.error('  - enhanced_products_*.json (from previous enhancement)');
  console.error('  - flattened_products.json (original file)');
  process.exit(1);
}

function loadProductsFile(filePath) {
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

function extractCategoryFromPath(productPath) {
  // Product path format: "bakeries_biscuits/bakery_snacks"
  // We want the first part (category group)
  if (!productPath || typeof productPath !== 'string') {
    return null;
  }
  
  const parts = productPath.split('/');
  return parts[0];
}

function addItemBackgroundColors(productsData) {
  console.log('🎨 Adding itemBackgroundColor to products...');
  
  const enhanced = JSON.parse(JSON.stringify(productsData)); // Deep clone
  let enhancedCount = 0;
  let noPathCount = 0;
  let unknownCategoryCount = 0;
  const unknownCategories = new Set();
  
  if (!enhanced.dynamic_product_info) {
    console.error('❌ No dynamic_product_info found in products file');
    process.exit(1);
  }
  
  console.log(`📊 Processing ${Object.keys(enhanced.dynamic_product_info).length} products...`);
  
  for (const [productId, productInfo] of Object.entries(enhanced.dynamic_product_info)) {
    if (!productInfo.path) {
      noPathCount++;
      console.log(`  ⚠️  Product ${productId} has no path field`);
      continue;
    }
    
    const categoryGroup = extractCategoryFromPath(productInfo.path);
    
    if (!categoryGroup) {
      noPathCount++;
      console.log(`  ⚠️  Could not extract category from path: ${productInfo.path}`);
      continue;
    }
    
    const backgroundColor = CATEGORY_BACKGROUND_COLORS[categoryGroup];
    
    if (backgroundColor) {
      productInfo.itemBackgroundColor = backgroundColor;
      enhancedCount++;
      
      // Show progress for first few items
      if (enhancedCount <= 5) {
        const productName = productInfo.name || 'Unknown Product';
        console.log(`  ✅ ${productName} (${categoryGroup}) → ${backgroundColor}`);
      }
    } else {
      unknownCategoryCount++;
      unknownCategories.add(categoryGroup);
      console.log(`  ❓ Unknown category: ${categoryGroup} for product ${productId}`);
    }
  }
  
  return {
    enhanced,
    stats: {
      enhancedCount,
      noPathCount,
      unknownCategoryCount,
      unknownCategories: Array.from(unknownCategories),
      totalProcessed: Object.keys(enhanced.dynamic_product_info).length
    }
  };
}

function saveEnhancedData(enhanced, stats, originalFilePath) {
  // Generate filename with timestamp
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFile = path.join(PROJECT_ROOT, `products_with_colors_${timestamp}.json`);
  
  console.log('💾 Saving enhanced data with itemBackgroundColor...');
  
  try {
    fs.writeFileSync(outputFile, JSON.stringify(enhanced, null, 2), 'utf8');
    console.log(`✅ Enhanced data saved to: ${path.basename(outputFile)}`);
    
    // Create a summary report
    const summaryFile = path.join(PROJECT_ROOT, `color_enhancement_summary_${timestamp}.txt`);
    
    let summary = `ITEM BACKGROUND COLOR ENHANCEMENT SUMMARY\\n`;
    summary += `${'='.repeat(50)}\\n\\n`;
    summary += `Enhancement Date: ${new Date().toISOString()}\\n`;
    summary += `Source File: ${path.basename(originalFilePath)}\\n`;
    summary += `Total Products Processed: ${stats.totalProcessed}\\n`;
    summary += `Successfully Enhanced: ${stats.enhancedCount}\\n`;
    summary += `No Path Field: ${stats.noPathCount}\\n`;
    summary += `Unknown Categories: ${stats.unknownCategoryCount}\\n`;
    summary += `Enhancement Success Rate: ${((stats.enhancedCount / stats.totalProcessed) * 100).toFixed(1)}%\\n\\n`;
    
    summary += `CATEGORY COLOR MAPPING USED:\\n`;
    summary += `${'-'.repeat(30)}\\n`;
    Object.entries(CATEGORY_BACKGROUND_COLORS).forEach(([category, color]) => {
      summary += `${category}: ${color}\\n`;
    });
    summary += '\\n';
    
    if (stats.unknownCategories.length > 0) {
      summary += `UNKNOWN CATEGORIES FOUND:\\n`;
      summary += `${'-'.repeat(25)}\\n`;
      stats.unknownCategories.forEach(category => {
        summary += `${category}\\n`;
      });
      summary += '\\n';
    }
    
    summary += `FIELD ADDED:\\n`;
    summary += `${'-'.repeat(15)}\\n`;
    summary += `• itemBackgroundColor - Color value for category background\\n`;
    
    fs.writeFileSync(summaryFile, summary, 'utf8');
    console.log(`📄 Summary saved to: ${path.basename(summaryFile)}`);
    
    return { outputFile, summaryFile };
    
  } catch (error) {
    console.error('❌ Error saving files:', error.message);
    throw error;
  }
}

function main() {
  try {
    console.log('\\n🎨 Category Background Color Mapping:');
    Object.entries(CATEGORY_BACKGROUND_COLORS).forEach(([category, color]) => {
      console.log(`  ${category}: ${color}`);
    });
    console.log('');
    
    // Find and load the products file
    const productsFilePath = findLatestProductsFile();
    const productsData = loadProductsFile(productsFilePath);
    
    // Validate data structure
    if (!productsData.dynamic_product_info) {
      console.error('❌ No dynamic_product_info found in products file');
      process.exit(1);
    }
    
    console.log(`\\n📊 Data Overview:`);
    console.log(`  Products to process: ${Object.keys(productsData.dynamic_product_info).length}`);
    console.log(`  Categories available: ${Object.keys(CATEGORY_BACKGROUND_COLORS).length}`);
    
    // Add itemBackgroundColor to products
    const { enhanced, stats } = addItemBackgroundColors(productsData);
    
    // Save results
    const { outputFile, summaryFile } = saveEnhancedData(enhanced, stats, productsFilePath);
    
    // Final summary
    console.log('\\n' + '='.repeat(60));
    console.log('🎉 COLOR ENHANCEMENT COMPLETED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log(`🎨 Products Enhanced: ${stats.enhancedCount}`);
    console.log(`⚠️  Products with No Path: ${stats.noPathCount}`);
    console.log(`❓ Unknown Categories: ${stats.unknownCategoryCount}`);
    console.log(`📈 Success Rate: ${((stats.enhancedCount / stats.totalProcessed) * 100).toFixed(1)}%`);
    console.log(`💾 Output File: ${path.basename(outputFile)}`);
    console.log(`📄 Summary File: ${path.basename(summaryFile)}`);
    console.log('='.repeat(60));
    
  } catch (error) {
    console.error('\\n💥 Color enhancement failed:', error.message);
    process.exit(1);
  }
}

// Run the script
main();
