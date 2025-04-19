import fs from 'fs';
import path from 'path';

// Path to the products folder
const PRODUCTS_FOLDER = path.join(process.cwd(), 'products');

console.log('\nChecking products folder...');
console.log('=========================');
console.log(`Looking for products folder at: ${PRODUCTS_FOLDER}`);

// Check if the products folder exists
if (!fs.existsSync(PRODUCTS_FOLDER)) {
  console.error('Products folder not found!');
  console.log('Please create a "products" folder in your project directory and add some images.');
  process.exit(1);
}

console.log('Products folder found!');

// Get all files in the products folder
const files = fs.readdirSync(PRODUCTS_FOLDER);
console.log(`\nTotal files found: ${files.length}`);

// Filter for image files
const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
const imageFiles = files.filter(file => {
  const ext = path.extname(file).toLowerCase();
  return imageExtensions.includes(ext);
});

console.log(`Total image files found: ${imageFiles.length}`);

if (imageFiles.length === 0) {
  console.error('\nNo image files found in the products folder!');
  console.log('Please add some image files (.jpg, .jpeg, .png, .webp, .gif) to the products folder.');
  process.exit(1);
}

console.log('\nImage files found:');
console.log('==================');
imageFiles.forEach((file, index) => {
  const filePath = path.join(PRODUCTS_FOLDER, file);
  const stats = fs.statSync(filePath);
  const fileSizeInKB = (stats.size / 1024).toFixed(2);
  console.log(`${index + 1}. ${file} (${fileSizeInKB} KB)`);
});

console.log('\nReady for image upload! ✓');
