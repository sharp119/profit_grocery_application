import fs from 'fs';
import path from 'path';

console.log('🖼️ PRODUCT IMAGE PATH ENHANCEMENT');
console.log('📋 Adding imagePath to each product from Firestore export...');
console.log('='.repeat(60));

// File paths
const PROJECT_ROOT = 'F:\\Soup\\projects\\profit_grocery_application';
const FIRESTORE_EXPORT_PATH = 'F:\\Soup\\projects\\profit_grocery_application\\db_upload\\firestore_products_export_2025-05-26T15-57-13-577Z.json';

function findLatestProductsFile() {
  console.log('🔍 Looking for products file...');
  
  // First, try to find the most recent enhanced file
  try {
    const files = fs.readdirSync(PROJECT_ROOT);
    const enhancedFiles = files.filter(file => 
      (file.startsWith('enhanced_products_') || 
       file.startsWith('products_with_colors_')) && 
      file.endsWith('.json')
    );
    
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
  console.error('  - enhanced_products_*.json');
  console.error('  - products_with_colors_*.json');
  console.error('  - flattened_products.json (original file)');
  process.exit(1);
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

function createImagePathLookupMap(firestoreData) {
  console.log('🗂️  Creating image path lookup map from Firestore export...');
  
  const imageMap = new Map();
  let totalProducts = 0;
  
  // Traverse the nested structure: products -> categoryGroup -> categoryItem -> products array
  for (const [categoryGroup, categoryItems] of Object.entries(firestoreData.products)) {
    for (const [categoryItem, products] of Object.entries(categoryItems)) {
      for (const product of products) {
        if (product.imagePath) {
          imageMap.set(product.id, product.imagePath);
          totalProducts++;
        }
      }
    }
  }
  
  console.log(`✅ Created image lookup map with ${totalProducts} products`);
  return imageMap;
}

function addImagePaths(productsData, imageMap) {
  console.log('🖼️ Adding imagePath to products...');
  
  const enhanced = JSON.parse(JSON.stringify(productsData)); // Deep clone
  let enhancedCount = 0;
  let notFoundCount = 0;
  const notFoundIds = [];
  
  if (!enhanced.dynamic_product_info) {
    console.error('❌ No dynamic_product_info found in products file');
    process.exit(1);
  }
  
  console.log(`📊 Processing ${Object.keys(enhanced.dynamic_product_info).length} products...`);
  
  for (const [productId, productInfo] of Object.entries(enhanced.dynamic_product_info)) {
    const imagePath = imageMap.get(productId);
    
    if (imagePath) {
      productInfo.imagePath = imagePath;
      enhancedCount++;
      
      // Show progress for first few items
      if (enhancedCount <= 5) {
        const productName = productInfo.name || productId;
        console.log(`  ✅ ${productName} → Image added`);
      }
    } else {
      notFoundCount++;
      notFoundIds.push(productId);
      
      // Show first few missing items
      if (notFoundCount <= 5) {
        console.log(`  ⚠️  No image found for product: ${productId}`);
      }
    }
  }
  
  return {
    enhanced,
    stats: {
      enhancedCount,
      notFoundCount,
      notFoundIds,
      totalProcessed: Object.keys(enhanced.dynamic_product_info).length
    }
  };
}

function saveEnhancedData(enhanced, stats, originalFilePath) {
  // Generate filename with timestamp
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFile = path.join(PROJECT_ROOT, `products_with_images_${timestamp}.json`);
  
  console.log('💾 Saving enhanced data with image paths...');
  
  try {
    fs.writeFileSync(outputFile, JSON.stringify(enhanced, null, 2), 'utf8');
    console.log(`✅ Enhanced data saved to: ${path.basename(outputFile)}`);
    
    // Create a summary report
    const summaryFile = path.join(PROJECT_ROOT, `image_enhancement_summary_${timestamp}.txt`);
    
    let summary = `IMAGE PATH ENHANCEMENT SUMMARY\\n`;
    summary += `${'='.repeat(50)}\\n\\n`;
    summary += `Enhancement Date: ${new Date().toISOString()}\\n`;
    summary += `Source File: ${path.basename(originalFilePath)}\\n`;
    summary += `Firestore Export: ${path.basename(FIRESTORE_EXPORT_PATH)}\\n`;
    summary += `Total Products Processed: ${stats.totalProcessed}\\n`;
    summary += `Successfully Enhanced: ${stats.enhancedCount}\\n`;
    summary += `Images Not Found: ${stats.notFoundCount}\\n`;
    summary += `Enhancement Success Rate: ${((stats.enhancedCount / stats.totalProcessed) * 100).toFixed(1)}%\\n\\n`;
    
    if (stats.notFoundCount > 0) {
      summary += `PRODUCTS WITHOUT IMAGES:\\n`;
      summary += `${'-'.repeat(30)}\\n`;
      stats.notFoundIds.slice(0, 20).forEach(id => {
        summary += `${id}\\n`;
      });
      if (stats.notFoundIds.length > 20) {
        summary += `... and ${stats.notFoundIds.length - 20} more\\n`;
      }
      summary += '\\n';
    }
    
    summary += `FIELD ADDED:\\n`;
    summary += `${'-'.repeat(15)}\\n`;
    summary += `• imagePath - Firebase Storage URL for product image\\n\\n`;
    
    summary += `IMAGE URL FORMAT:\\n`;
    summary += `${'-'.repeat(20)}\\n`;
    summary += `https://firebasestorage.googleapis.com/v0/b/profit-grocery.firebasestorage.app/o/products%2F{category}%2F{item}%2F{productId}%2Fimage.png?alt=media&token={token}\\n`;
    
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
    // Check if Firestore export exists
    if (!fs.existsSync(FIRESTORE_EXPORT_PATH)) {
      console.error('❌ Firestore export file not found!');
      console.error(`Expected: ${FIRESTORE_EXPORT_PATH}`);
      console.error('Please ensure the Firestore export file exists.');
      process.exit(1);
    }
    
    // Find and load the products file
    const productsFilePath = findLatestProductsFile();
    const productsData = loadJsonFile(productsFilePath);
    
    // Load Firestore export
    const firestoreExport = loadJsonFile(FIRESTORE_EXPORT_PATH);
    
    // Validate data structure
    if (!productsData.dynamic_product_info) {
      console.error('❌ No dynamic_product_info found in products file');
      process.exit(1);
    }
    
    if (!firestoreExport.products) {
      console.error('❌ No products found in Firestore export file');
      process.exit(1);
    }
    
    console.log(`\\n📊 Data Overview:`);
    console.log(`  Products to enhance: ${Object.keys(productsData.dynamic_product_info).length}`);
    console.log(`  Firestore products: ${firestoreExport.metadata.totalProducts}`);
    console.log(`  Firestore categories: ${firestoreExport.metadata.totalCategoryGroups}`);
    
    // Create image lookup map and enhance products
    const imageMap = createImagePathLookupMap(firestoreExport);
    const { enhanced, stats } = addImagePaths(productsData, imageMap);
    
    // Save results
    const { outputFile, summaryFile } = saveEnhancedData(enhanced, stats, productsFilePath);
    
    // Final summary
    console.log('\\n' + '='.repeat(60));
    console.log('🎉 IMAGE PATH ENHANCEMENT COMPLETED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log(`🖼️ Products Enhanced: ${stats.enhancedCount}`);
    console.log(`⚠️  Images Not Found: ${stats.notFoundCount}`);
    console.log(`📈 Success Rate: ${((stats.enhancedCount / stats.totalProcessed) * 100).toFixed(1)}%`);
    console.log(`💾 Output File: ${path.basename(outputFile)}`);
    console.log(`📄 Summary File: ${path.basename(summaryFile)}`);
    console.log('='.repeat(60));
    
    if (stats.notFoundCount > 0) {
      console.log('\\n💡 Note: Some products may not have images in the Firestore export.');
      console.log("   This could be normal if images have not been uploaded for those products yet.");
    }
    
  } catch (error) {
    console.error('\\n💥 Image path enhancement failed:', error.message);
    process.exit(1);
  }
}

// Run the script
main();
