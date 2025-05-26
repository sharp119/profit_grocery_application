import fs from 'fs';
import path from 'path';

console.log('🔄 PRODUCT DATA ENHANCEMENT SCRIPT');
console.log('📋 Adding name, brand, weight, and tags to flattened products...');
console.log('='.repeat(60));

// File paths
const FLATTENED_PRODUCTS_PATH = 'F:\\Soup\\projects\\profit_grocery_application\\flattened_products.json';
const FIRESTORE_EXPORT_PATH = 'F:\\Soup\\projects\\profit_grocery_application\\db_upload\\firestore_products_export_2025-05-26T15-57-13-577Z.json';

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

function createProductLookupMap(firestoreData) {
  console.log('🗂️  Creating product lookup map from Firestore export...');
  
  const productMap = new Map();
  let totalProducts = 0;
  
  // Traverse the nested structure: products -> categoryGroup -> categoryItem -> products array
  for (const [categoryGroup, categoryItems] of Object.entries(firestoreData.products)) {
    for (const [categoryItem, products] of Object.entries(categoryItems)) {
      for (const product of products) {
        productMap.set(product.id, {
          name: product.name,
          brand: product.brand,
          weight: product.weight,
          tags: product.tags || []
        });
        totalProducts++;
      }
    }
  }
  
  console.log(`✅ Created lookup map with ${totalProducts} products`);
  return productMap;
}

function enhanceFlattendProducts(flattened, productMap) {
  console.log('🔧 Enhancing flattened products with name, brand, weight, and tags...');
  
  const enhanced = JSON.parse(JSON.stringify(flattened)); // Deep clone
  let enhancedCount = 0;
  let notFoundCount = 0;
  const notFoundIds = [];
  
  // Process dynamic_product_info
  if (enhanced.dynamic_product_info) {
    console.log(`📊 Processing ${Object.keys(enhanced.dynamic_product_info).length} products in dynamic_product_info...`);
    
    for (const [productId, productInfo] of Object.entries(enhanced.dynamic_product_info)) {
      const firestoreProduct = productMap.get(productId);
      
      if (firestoreProduct) {
        // Add ONLY the 4 requested fields
        productInfo.name = firestoreProduct.name;
        productInfo.brand = firestoreProduct.brand;
        productInfo.weight = firestoreProduct.weight;
        productInfo.tags = firestoreProduct.tags;
        
        enhancedCount++;
        
        // Show progress for first few items
        if (enhancedCount <= 5) {
          console.log(`  ✅ Enhanced: ${firestoreProduct.name} (${firestoreProduct.brand}) - ${firestoreProduct.weight}`);
        }
      } else {
        notFoundCount++;
        notFoundIds.push(productId);
        
        // Show first few missing items
        if (notFoundCount <= 5) {
          console.log(`  ⚠️  Product not found in Firestore: ${productId}`);
        }
      }
    }
  }
  
  return {
    enhanced,
    stats: {
      enhancedCount,
      notFoundCount,
      notFoundIds,
      totalProcessed: enhancedCount + notFoundCount
    }
  };
}

function saveEnhancedData(enhanced, stats) {
  // Generate filename with timestamp
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFile = `F:\\Soup\\projects\\profit_grocery_application\\enhanced_products_${timestamp}.json`;
  
  console.log('💾 Saving enhanced data...');
  
  try {
    fs.writeFileSync(outputFile, JSON.stringify(enhanced, null, 2), 'utf8');
    console.log(`✅ Enhanced data saved to: ${path.basename(outputFile)}`);
    
    // Create a summary report
    const summaryFile = `F:\\Soup\\projects\\profit_grocery_application\\enhancement_summary_${timestamp}.txt`;
    
    let summary = `PRODUCT DATA ENHANCEMENT SUMMARY\\n`;
    summary += `${'='.repeat(50)}\\n\\n`;
    summary += `Enhancement Date: ${new Date().toISOString()}\\n`;
    summary += `Total Products Processed: ${stats.totalProcessed}\\n`;
    summary += `Successfully Enhanced: ${stats.enhancedCount}\\n`;
    summary += `Not Found in Firestore: ${stats.notFoundCount}\\n`;
    summary += `Enhancement Success Rate: ${((stats.enhancedCount / stats.totalProcessed) * 100).toFixed(1)}%\\n\\n`;
    
    if (stats.notFoundCount > 0) {
      summary += `PRODUCTS NOT FOUND IN FIRESTORE:\\n`;
      summary += `${'-'.repeat(30)}\\n`;
      stats.notFoundIds.forEach(id => {
        summary += `${id}\\n`;
      });
      summary += '\\n';
    }
    
    summary += `FIELDS ADDED TO EACH PRODUCT:\\n`;
    summary += `${'-'.repeat(30)}\\n`;
    summary += `• name - Product name\\n`;
    summary += `• brand - Brand name\\n`;
    summary += `• weight - Product weight/size\\n`;
    summary += `• tags - Product tags array\\n`;
    
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
    // Load both data files
    const flattened = loadJsonFile(FLATTENED_PRODUCTS_PATH);
    const firestoreExport = loadJsonFile(FIRESTORE_EXPORT_PATH);
    
    // Validate data structure
    if (!flattened.dynamic_product_info) {
      console.error('❌ No dynamic_product_info found in flattened products file');
      process.exit(1);
    }
    
    if (!firestoreExport.products) {
      console.error('❌ No products found in Firestore export file');
      process.exit(1);
    }
    
    console.log(`\\n📊 Data Overview:`);
    console.log(`  Flattened products: ${Object.keys(flattened.dynamic_product_info).length}`);
    console.log(`  Firestore products: ${firestoreExport.metadata.totalProducts}`);
    console.log(`  Firestore categories: ${firestoreExport.metadata.totalCategoryGroups}`);
    
    // Create lookup map and enhance products
    const productMap = createProductLookupMap(firestoreExport);
    const { enhanced, stats } = enhanceFlattendProducts(flattened, productMap);
    
    // Save results
    const { outputFile, summaryFile } = saveEnhancedData(enhanced, stats);
    
    // Final summary
    console.log('\\n' + '='.repeat(60));
    console.log('🎉 ENHANCEMENT COMPLETED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log(`📊 Enhanced Products: ${stats.enhancedCount}`);
    console.log(`⚠️  Products Not Found: ${stats.notFoundCount}`);
    console.log(`📈 Success Rate: ${((stats.enhancedCount / stats.totalProcessed) * 100).toFixed(1)}%`);
    console.log(`💾 Output File: ${path.basename(outputFile)}`);
    console.log(`📄 Summary File: ${path.basename(summaryFile)}`);
    console.log('='.repeat(60));
    
  } catch (error) {
    console.error('\\n💥 Enhancement failed:', error.message);
    process.exit(1);
  }
}

// Run the script
main();
