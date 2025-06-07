import fs from 'fs';
import path from 'path';

console.log('🚀 PRODUCT DATA TRANSFORMATION SCRIPT');
console.log('📋 Converting products to the new detailed structure with enhanced images and tags...');
console.log('='.repeat(60));

// --- Configuration ---
const INPUT_FILE_PATH = 'F:\\Soup\\projects\\profit_grocery_application\\db_upload\\firestore_products_export_2025-05-26T15-57-13-577Z.json';
const OUTPUT_DIR = 'F:\\Soup\\projects\\profit_grocery_application\\db_upload';

// --- Sample Sections (provided by user) ---

const descriptionSections = [
  {
    "description_section": {
      "description": "**Fresh, farm-picked organic apples** sourced directly from pristine orchards. These apples are perfect for a healthy snack, juicing, or adding a natural sweetness to your baking. Grown meticulously without harmful pesticides, they guarantee a pure taste and exceptional nutritional value. Enjoy a crisp bite every time! **Certified organic and sustainably farmed.**"
    }
  },
  {
    "description_section": {
      "description": "Indulge in the rich, deep flavor of our **premium dark chocolate bar**. Crafted with a remarkable 70% cocoa content, this bar is an absolute delight for true chocolate connoisseurs and a sophisticated treat. Its **smooth, velvety texture** melts in your mouth, leaving a lingering, satisfying taste.\n\nKey features:\n- **Intense cocoa flavor**: A bold and authentic chocolate experience.\n- **Luxurious texture**: Smooth and rich, perfect for savoring.\n- **Versatile treat**: Ideal for gifting, personal indulgence, or gourmet recipes.\n- **Ethically sourced**: Made with cocoa from sustainable farms.",
      "instructions": "Store in a cool, dark, and dry place, ideally between 15-18°C (59-64°F). Avoid direct sunlight and strong odors to preserve its delicate aroma and texture. **Do not refrigerate** unless necessary to prevent blooming."
    }
  },
  {
    "description_section": {
      "description": "**Crispy and golden potato chips**, thinly sliced and cooked to perfection, then lightly seasoned with just the right amount of salt for that classic, irresistible crunch. They are the ideal snack for any moment of the day – whether you're relaxing at home, having a picnic, or needing a quick bite on the go. **Experience pure potato goodness!**"
    }
  },
  {
    "description_section": {
      "description": "**Hand-picked organic spinach**, carefully selected from local farms, ensures you get your daily dose of fresh greens. Each leaf is thoroughly washed and ready for immediate use, saving you prep time. Packed with essential nutrients, our spinach is a versatile ingredient for countless dishes.\n\nWhy choose our organic spinach?\n- **Rich in vital nutrients**: An excellent source of iron, Vitamin K, Vitamin A, and Vitamin C.\n- **Sustainably farmed**: Grown using eco-friendly practices that protect the environment.\n- **Versatile culinary ingredient**: Perfect for fresh salads, nutrient-packed smoothies, hearty curries, or quick sautés.\n- **No artificial additives**: Pure, natural goodness.",
      "instructions": "1. For best results, **lightly rinse again** before use, even though it comes pre-washed.\n2. Keep refrigerated in its original packaging or an airtight container to maintain freshness.\n3. **Consume within 3-4 days** of opening for optimal taste and texture. If not used immediately, you can blanch and freeze for longer storage."
    }
  },
  {
    "description_section": {
      "description": "**Soft and fluffy white bread**, freshly baked every morning with a golden-brown crust. This classic loaf is a timeless household staple, offering a versatile base for countless meals. Whether it's for preparing hearty sandwiches, making crispy toast for breakfast, or using it as a side for your favorite dishes, its **consistent quality and delightful taste** make it a family favorite. It's truly everyday comfort, perfected."
    }
  }
];

const highlightsSections = [
  {
    "highlights_section": {
      "highlights": {
        "Volume": "1 Liter",
        "Type": "Full Cream Milk",
        "Source": "Local Dairy Farm, Alpine Region",
        "Certification": "Pasteurized, Homogenized, FSSAI Certified",
        "Fat Content": "6% min.",
        "Protein Content": "3.5g per 100ml",
        "Vitamins Added": "Vitamin A, Vitamin D",
        "Packaging": "Tetra Pak, Recyclable",
        "Shelf Life": "90 Days (unopened)",
        "Usage": "Drinking, Tea/Coffee, Dessert Making"
      }
    }
  },
  {
    "highlights_section": {
      "highlights": {
        "Flavor": "Strawberry Delight",
        "Texture": "Extra Thick & Creamy",
        "Pack Size": "150g Cup (Single Serving)",
        "Storage": "Keep Refrigerated below 4°C (Do Not Freeze)",
        "Benefit": "High in Probiotic Cultures, Digestive Health",
        "Sweetness Level": "Moderately Sweet",
        "Fruit Content": "Real Strawberry Pieces",
        "Serving Suggestion": "Breakfast, Snack, Dessert Topping",
        "Allergen Info": "Contains Dairy"
      },
      "ingredients": {
        "Main Components": "Fresh Pasteurized Milk, Strawberry Puree (20%), Live Active Yogurt Cultures",
        "Sweetener Type": "Natural Cane Sugar, Fructose (from fruit)",
        "Active Cultures": "S. thermophilus, L. bulgaricus, L. acidophilus, Bifidobacterium lactis (Added Probiotics)",
        "Stabilizers": "Pectin, Agar-Agar (Natural Thickeners)",
        "Additives": "Natural Strawberry Flavor, Beetroot Juice Concentrate (for color)"
      }
    }
  },
  {
    "highlights_section": {
      "highlights": {
        "Weight": "500g Pouch",
        "Grain Type": "Premium Long Grain Basmati Rice",
        "Aroma": "Naturally Aromatic, Distinctive Fragrance, Well-Aged (2 years)",
        "Cooking Time": "15-20 min (Stovetop), 12 min (Pressure Cooker), 25 min (Rice Cooker)",
        "Texture After Cooking": "Fluffy, Separated Grains, Non-sticky",
        "Expansion Ratio": "Expands to 2.5x its size",
        "Origin": "Himalayan Foothills",
        "Best For": "Biryani, Pilaf, Side Dish",
        "Gluten Status": "Naturally Gluten-Free"
      }
    }
  },
  {
    "highlights_section": {
      "highlights": {
        "Main Ingredient": "Premium California Almonds",
        "Origin Region": "Central Valley, California, USA",
        "Key Benefit": "Rich in Vitamin E, Magnesium, Antioxidants, Healthy Fats",
        "Ideal Use": "Healthy Snacking, Baking, Granola, Smoothie Topping, Almond Milk Preparation",
        "Processing": "Raw, Unroasted, Unsalted",
        "Purity": "100% Natural, No Preservatives",
        "Fiber Content": "High Dietary Fiber",
        "Storage Advice": "Store in airtight container in cool, dry place"
      },
      "ingredients": {
        "Composition": "100% Pure Raw California Almonds (Prunus dulcis)",
        "Allergens Present": "Contains Tree Nuts",
        "Certifications": "Non-GMO Verified, Gluten-Free, Vegan"
      }
    }
  },
  {
    "highlights_section": {
      "highlights": {
        "Pack Quantity": "12 Large Eggs",
        "Shell Color": "White",
        "Farm Type": "Cage-Free, Free-Range, Pasture-Raised",
        "Egg Size": "Large (approx. 60g each), Grade A",
        "Nutritional Info": "Rich in Protein, Omega-3s, Vitamin D, Choline",
        "Yolk Color": "Vibrant Yellow/Orange",
        "Taste Profile": "Farm-Fresh, Rich Flavor",
        "Quality Assurance": "Inspected for freshness and quality",
        "Recommended Use": "Baking, Frying, Scrambling, Boiling"
      }
    }
  }
];

const sellerInfoSections = [
  {
    "seller_info_section": {
      "sourceOfOrigin": "Organic Farms, Himachal Pradesh, India",
      "sellerName": "Green Valley Organics & Naturals",
      "fssai": "12345678901234",
      "address": "456 Orchard Road, Fresh Produce Zone, Shimla, HP 171001",
      "customerCare": "1800-111-222 (Toll-Free)",
      "email": "support@greenvalleyorganics.com",
      "returnPolicy": "7-day easy return if unsatisfied with quality."
    }
  },
  {
    "seller_info_section": {
      "sourceOfOrigin": "Brussels, Belgium (Imported)",
      "sellerName": "Gourmet Chocolatiers International",
      "fssai": "N/A (Imported Goods)",
      "address": "789 Cocoa Lane, Sweet Delights District, Global Import Hub, BL 98765",
      "customerCare": "+32-456-7890 (International)",
      "email": "info@gourmetchocolatiers.be",
      "certifications": "Fair Trade Certified"
    }
  },
  {
    "seller_info_section": {
      "sourceOfOrigin": "Local Production Unit, India",
      "sellerName": "Crisp N Munch Pvt Ltd. - Quality Snacks",
      "customerCare": "1800-333-444 (India)",
      "website": "www.crispnmunch.in"
    }
  },
  {
    "seller_info_section": {
      "sourceOfOrigin": "Direct from Partner Farmers, Karnataka",
      "sellerName": "Daily Fresh Produce Cooperative",
      "address": "101 Market Street, Veggieville, Bengaluru, KA 560001",
      "deliveryInfo": "Next-day delivery available in select cities.",
      "paymentOptions": "All major cards, UPI accepted"
    }
  },
  {
    "seller_info_section": {
      "sourceOfOrigin": "Regional Mill, Punjab, India",
      "sellerName": "Healthy Grains Co. - Wholesome Products",
      "fssai": "98765432109876",
      "customerCare": "1800-555-888",
      "contactPerson": "Sales Department",
      "businessHours": "Mon-Sat: 9 AM - 6 PM"
    }
  }
];

// --- Helper Functions ---

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

function getRandomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function getRandomNumber(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// Function to extract unique words from a string for tags
function getWordsForTags(text) {
  if (!text) return [];
  // Split by spaces, hyphens, underscores, and ampersands
  const words = text.toLowerCase().split(/[\s-&_]+/);
  return [...new Set(words.filter(word => word.length > 1))]; // Filter out very short words
}

let allImagePaths = []; // Global array to store all image paths

function transformProduct(oldProduct) {
  // Randomly select sections
  const selectedDescriptionSection = getRandomElement(descriptionSections).description_section;
  const selectedHighlightsSection = getRandomElement(highlightsSections).highlights_section;
  const selectedSellerInfoSection = getRandomElement(sellerInfoSections).seller_info_section;

  // --- Image List Generation ---
  const imagesList = [];
  // Add the product's own image first, if it exists
  if (oldProduct.imagePath) {
    imagesList.push(oldProduct.imagePath);
  }

  // Determine how many additional images to add (between 2 and 5, for a total of 3 to 6)
  const numExtraImages = getRandomNumber(2, 5);

  // Add random images from the global pool
  // Ensure there are enough unique images in the global pool
  const tempImagePool = [...allImagePaths]; // Create a mutable copy
  for (let i = 0; i < numExtraImages; i++) {
    if (tempImagePool.length > 0) {
        const randomIndex = Math.floor(Math.random() * tempImagePool.length);
        imagesList.push(tempImagePool[randomIndex]);
        tempImagePool.splice(randomIndex, 1); // Remove to avoid immediate duplicates if pool is small
    } else {
        // If pool is exhausted, refill it or stop adding
        console.warn('Image pool exhausted, recycling images.');
        tempImagePool.push(...allImagePaths); // Recycle for more images
        if (tempImagePool.length > 0) {
             const randomIndex = Math.floor(Math.random() * tempImagePool.length);
             imagesList.push(tempImagePool[randomIndex]);
             tempImagePool.splice(randomIndex, 1);
        } else {
            break; // No images available at all
        }
    }
  }

  // Ensure imagesList has between 3 and 6 elements if possible, and remove duplicates
  const finalImages = [...new Set(imagesList)].slice(0, getRandomNumber(3,6));
  if (finalImages.length < 3 && oldProduct.imagePath) {
    // If we couldn't get enough unique images, ensure at least the main image is there and pad with placeholders
    while (finalImages.length < 3) {
      finalImages.push(`https://via.placeholder.com/150?text=Placeholder+${finalImages.length + 1}`);
    }
  }


  // --- Tags Generation ---
  const productTags = new Set();
  getWordsForTags(oldProduct.name).forEach(tag => productTags.add(tag));
  getWordsForTags(oldProduct.brand).forEach(tag => productTags.add(tag));
  getWordsForTags(oldProduct.productType).forEach(tag => productTags.add(tag));
  // Add any existing tags if present, though current export has empty tags array
  if (Array.isArray(oldProduct.tags)) {
      oldProduct.tags.forEach(tag => productTags.add(tag.toLowerCase()));
  }

  // Construct the new product object
  const newProduct = {
    id: oldProduct.id,
    hero_section: {
      name: oldProduct.name || 'Unnamed Product',
      brand: oldProduct.brand || 'Unknown Brand',
      productType: oldProduct.productType || 'General Product',
      rating: parseFloat((Math.random() * (5.0 - 3.5) + 3.5).toFixed(1)), // Random rating between 3.5 and 5.0
      reviewCount: Math.floor(Math.random() * 100) + 1, // Random review count between 1 and 100
      images: finalImages
    },
    highlights_section: selectedHighlightsSection,
    description_section: selectedDescriptionSection,
    seller_info_section: selectedSellerInfoSection,
    additional_info: {
      category: oldProduct.categoryGroup,
      subCategory: oldProduct.categoryItem,
      sku: oldProduct.sku || 'N/A',
      isFeatured: oldProduct.isFeatured || false,
      isActive: oldProduct.isActive || true,
      tags: Array.from(productTags), // Convert Set back to Array
      createdAt: oldProduct.createdAt,
      updatedAt: oldProduct.updatedAt
    }
  };

  return newProduct;
}

// --- Main Function ---

function main() {
  try {
    // 1. Load the original JSON file
    const originalData = loadJsonFile(INPUT_FILE_PATH);

    // 2. Collect all image paths from the entire dataset
    for (const categoryGroupKey in originalData.products) {
      if (originalData.products.hasOwnProperty(categoryGroupKey)) {
        for (const categoryItemKey in originalData.products[categoryGroupKey]) {
          if (originalData.products[categoryGroupKey].hasOwnProperty(categoryItemKey)) {
            const productsArray = originalData.products[categoryGroupKey][categoryItemKey];
            productsArray.forEach(product => {
              if (product.imagePath) {
                allImagePaths.push(product.imagePath);
              }
            });
          }
        }
      }
    }
    console.log(`Collected ${allImagePaths.length} unique image paths from the entire dataset.`);
    // Shuffle the global image pool once for better randomness
    allImagePaths = [...new Set(allImagePaths)].sort(() => 0.5 - Math.random());


    // 3. Prepare the new structure
    const transformedData = {
      metadata: { ...originalData.metadata }, // Copy metadata
      products: {} // Initialize empty products object for the new structure
    };

    let totalTransformedProducts = 0;

    // 4. Iterate through category groups and items to transform products
    for (const categoryGroupKey in originalData.products) {
      if (originalData.products.hasOwnProperty(categoryGroupKey)) {
        transformedData.products[categoryGroupKey] = {}; // Create category group in new structure

        for (const categoryItemKey in originalData.products[categoryGroupKey]) {
          if (originalData.products[categoryGroupKey].hasOwnProperty(categoryItemKey)) {
            const productsArray = originalData.products[categoryGroupKey][categoryItemKey];

            // Transform each product in the array
            const newProductsArray = productsArray.map(product => {
              totalTransformedProducts++;
              return transformProduct(product);
            });

            // Assign the new array to the transformed structure
            transformedData.products[categoryGroupKey][categoryItemKey] = newProductsArray;
          }
        }
      }
    }

    // Update metadata for the new export
    transformedData.metadata.exportDate = new Date().toISOString();
    transformedData.metadata.totalProducts = totalTransformedProducts;
    transformedData.metadata.exportDurationMs = Date.now() - Date.parse(originalData.metadata.exportDate); // Approximate duration

    // 5. Save the new JSON file
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const outputFileName = `transformed_products_enhanced_export_${timestamp}.json`;
    const outputFilePath = path.join(OUTPUT_DIR, outputFileName);

    fs.writeFileSync(outputFilePath, JSON.stringify(transformedData, null, 2), 'utf8');

    console.log('\n' + '='.repeat(60));
    console.log('🎉 PRODUCT TRANSFORMATION COMPLETED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log(`📊 Total Products Transformed: ${totalTransformedProducts}`);
    console.log(`💾 Output saved to: ${outputFileName}`);
    console.log('='.repeat(60));

  } catch (error) {
    console.error('\n💥 Product transformation failed:', error.message);
    process.exit(1);
  }
}

// Run the script
main();