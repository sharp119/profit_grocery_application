import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, getDocs, updateDoc } from 'firebase/firestore';
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

// Product templates for different dairy & bread categories
const productTemplates = {
  bread: [
    {
      name: "White Bread Loaf",
      description: "Soft and fresh white bread perfect for sandwiches",
      inStock: true,
      price: 45,
      quantity: 30,
      weight: "400g",
      brand: "Fresh Bake",
      ingredients: "Wheat flour, sugar, yeast, salt, milk",
      nutritionalInfo: "Calories: 70 per slice, Protein: 2g, Carbs: 13g, Fat: 1g",
      sku: "BRD001",
      productType: "Bread"
    },
    {
      name: "Whole Wheat Bread",
      description: "Nutritious whole wheat bread high in fiber",
      inStock: true,
      price: 55,
      quantity: 25,
      weight: "400g",
      brand: "Healthy Choice",
      ingredients: "Whole wheat flour, wheat gluten, yeast, salt",
      nutritionalInfo: "Calories: 60 per slice, Protein: 3g, Carbs: 11g, Fat: 1g",
      sku: "BRD002",
      productType: "Bread"
    },
    {
      name: "Multigrain Bread",
      description: "Bread loaded with multiple grains and seeds",
      inStock: true,
      price: 65,
      quantity: 20,
      weight: "400g",
      brand: "Grain Master",
      ingredients: "Wheat flour, oats, millets, sunflower seeds, flaxseeds",
      nutritionalInfo: "Calories: 80 per slice, Protein: 4g, Carbs: 14g, Fat: 2g",
      sku: "BRD003",
      productType: "Bread"
    },
    {
      name: "Milk Bread",
      description: "Super soft milk bread for premium sandwiches",
      inStock: true,
      price: 60,
      quantity: 22,
      weight: "350g",
      brand: "Soft Delight",
      ingredients: "Wheat flour, milk, butter, sugar, yeast",
      nutritionalInfo: "Calories: 85 per slice, Protein: 3g, Carbs: 15g, Fat: 2g",
      sku: "BRD004",
      productType: "Bread"
    },
    {
      name: "Garlic Bread",
      description: "Aromatic garlic bread ready to bake",
      inStock: true,
      price: 75,
      quantity: 15,
      weight: "200g",
      brand: "Italian Baker",
      ingredients: "Wheat flour, garlic, butter, herbs",
      nutritionalInfo: "Calories: 110 per serving, Protein: 2g, Carbs: 16g, Fat: 5g",
      sku: "BRD005",
      productType: "Bread"
    }
  ],
  butter_cheese: [
    {
      name: "Salted Butter",
      description: "Creamy salted butter for spreading and cooking",
      inStock: true,
      price: 99,
      quantity: 50,
      weight: "200g",
      brand: "Pure Gold",
      ingredients: "Pasteurized cream, salt",
      nutritionalInfo: "Calories: 100 per tbsp, Fat: 11g, Sodium: 85mg",
      sku: "BTR001",
      productType: "Butter"
    },
    {
      name: "Unsalted Butter",
      description: "Perfect for baking and special recipes",
      inStock: true,
      price: 95,
      quantity: 40,
      weight: "200g",
      brand: "Bakers Choice",
      ingredients: "Pasteurized cream",
      nutritionalInfo: "Calories: 100 per tbsp, Fat: 11g",
      sku: "BTR002",
      productType: "Butter"
    },
    {
      name: "Processed Cheese Slices",
      description: "Ready-to-use cheese slices for sandwiches",
      inStock: true,
      price: 125,
      quantity: 35,
      weight: "200g (10 slices)",
      brand: "Dairy Delight",
      ingredients: "Cheddar cheese, milk solids, emulsifiers",
      nutritionalInfo: "Calories: 60 per slice, Protein: 4g, Fat: 4g",
      sku: "CHS001",
      productType: "Cheese"
    },
    {
      name: "Cheddar Cheese Block",
      description: "Sharp cheddar cheese for grating and melting",
      inStock: true,
      price: 299,
      quantity: 20,
      weight: "400g",
      brand: "Premium Cheese Co",
      ingredients: "Pasteurized milk, cheese cultures, salt",
      nutritionalInfo: "Calories: 110 per 28g, Protein: 7g, Fat: 9g",
      sku: "CHS002",
      productType: "Cheese"
    },
    {
      name: "Mozzarella Cheese",
      description: "Stretchy mozzarella perfect for pizza",
      inStock: true,
      price: 249,
      quantity: 25,
      weight: "200g",
      brand: "Pizza Perfect",
      ingredients: "Pasteurized milk, cheese cultures, salt",
      nutritionalInfo: "Calories: 85 per 28g, Protein: 6g, Fat: 6g",
      sku: "CHS003",
      productType: "Cheese"
    }
  ],
  condensed_milk: [
    {
      name: "Sweetened Condensed Milk",
      description: "Thick and sweet condensed milk for desserts",
      inStock: true,
      price: 79,
      quantity: 45,
      weight: "380g",
      brand: "Milky Magic",
      ingredients: "Milk, sugar",
      nutritionalInfo: "Calories: 130 per 2 tbsp, Sugar: 22g",
      sku: "COND001",
      productType: "Condensed Milk"
    },
    {
      name: "Premium Condensed Milk",
      description: "Extra creamy condensed milk for special desserts",
      inStock: true,
      price: 99,
      quantity: 30,
      weight: "400g",
      brand: "Chef's Choice",
      ingredients: "Milk, sugar, stabilizers",
      nutritionalInfo: "Calories: 140 per 2 tbsp, Sugar: 24g",
      sku: "COND002",
      productType: "Condensed Milk"
    },
    {
      name: "Condensed Milk Pouch",
      description: "Convenient pouch packaging for occasional use",
      inStock: true,
      price: 25,
      quantity: 100,
      weight: "85g",
      brand: "Quick Sweet",
      ingredients: "Milk, sugar",
      nutritionalInfo: "Calories: 130 per serving",
      sku: "COND003",
      productType: "Condensed Milk"
    },
    {
      name: "Sugar-Free Condensed Milk",
      description: "Unsweetened condensed milk for diabetics",
      inStock: true,
      price: 149,
      quantity: 15,
      weight: "400g",
      brand: "Health Plus",
      ingredients: "Milk, artificial sweeteners",
      nutritionalInfo: "Calories: 60 per 2 tbsp, Sugar: 0g",
      sku: "COND004",
      productType: "Condensed Milk"
    }
  ],
  cream_whitener: [
    {
      name: "Fresh Cream",
      description: "Pure fresh cream for cooking and desserts",
      inStock: true,
      price: 89,
      quantity: 30,
      weight: "200ml",
      brand: "Dairy Fresh",
      ingredients: "Pasteurized cream",
      nutritionalInfo: "Calories: 52 per tbsp, Fat: 5.5g",
      sku: "CRM001",
      productType: "Cream"
    },
    {
      name: "Heavy Whipping Cream",
      description: "High-fat cream perfect for whipping",
      inStock: true,
      price: 129,
      quantity: 20,
      weight: "250ml",
      brand: "Dessert Master",
      ingredients: "Heavy cream",
      nutritionalInfo: "Calories: 60 per tbsp, Fat: 6g",
      sku: "CRM002",
      productType: "Cream"
    },
    {
      name: "Coffee Whitener",
      description: "Powdered dairy whitener for coffee and tea",
      inStock: true,
      price: 69,
      quantity: 50,
      weight: "200g",
      brand: "Tea Time",
      ingredients: "Milk solids, sugar",
      nutritionalInfo: "Calories: 30 per tsp, Fat: 2g",
      sku: "WHT001",
      productType: "Whitener"
    },
    {
      name: "Non-Dairy Creamer",
      description: "Lactose-free creamer for coffee",
      inStock: true,
      price: 89,
      quantity: 35,
      weight: "400g",
      brand: "Vegan Choice",
      ingredients: "Vegetable oil, corn syrup solids",
      nutritionalInfo: "Calories: 10 per tsp, Fat: 0.5g",
      sku: "WHT002",
      productType: "Whitener"
    }
  ],
  curd_yogurt: [
    {
      name: "Plain Curd",
      description: "Fresh natural curd for daily consumption",
      inStock: true,
      price: 40,
      quantity: 60,
      weight: "400g",
      brand: "Fresh Dairy",
      ingredients: "Pasteurized milk, lactic acid bacteria",
      nutritionalInfo: "Calories: 60 per 100g, Protein: 3.5g, Fat: 3.3g",
      sku: "CRD001",
      productType: "Curd"
    },
    {
      name: "Greek Yogurt",
      description: "Thick and creamy Greek yogurt high in protein",
      inStock: true,
      price: 99,
      quantity: 35,
      weight: "200g",
      brand: "Greek Delight",
      ingredients: "Strained yogurt, live cultures",
      nutritionalInfo: "Calories: 130 per 170g, Protein: 15g, Fat: 5g",
      sku: "YGT001",
      productType: "Yogurt"
    },
    {
      name: "Flavored Yogurt - Strawberry",
      description: "Delicious strawberry flavored yogurt",
      inStock: true,
      price: 50,
      quantity: 45,
      weight: "150g",
      brand: "Fruity Yogurt",
      ingredients: "Milk, strawberry puree, sugar, cultures",
      nutritionalInfo: "Calories: 100 per cup, Protein: 3g, Sugar: 15g",
      sku: "YGT002",
      productType: "Yogurt"
    },
    {
      name: "Probiotic Yogurt",
      description: "Yogurt with additional probiotics for gut health",
      inStock: true,
      price: 79,
      quantity: 30,
      weight: "200g",
      brand: "Health Plus",
      ingredients: "Milk, probiotic cultures",
      nutritionalInfo: "Calories: 80 per 170g, Protein: 6g, Fat: 3g",
      sku: "YGT003",
      productType: "Yogurt"
    },
    {
      name: "Low Fat Curd",
      description: "99% fat-free curd for health conscious consumers",
      inStock: true,
      price: 45,
      quantity: 40,
      weight: "400g",
      brand: "Lite Choice",
      ingredients: "Skimmed milk, cultures",
      nutritionalInfo: "Calories: 40 per 100g, Protein: 4g, Fat: 0.5g",
      sku: "CRD002",
      productType: "Curd"
    }
  ],
  eggs: [
    {
      name: "Brown Eggs - 6 Pack",
      description: "Farm fresh brown eggs rich in nutrients",
      inStock: true,
      price: 45,
      quantity: 70,
      weight: "6 eggs",
      brand: "Farm Fresh",
      ingredients: "100% Natural eggs",
      nutritionalInfo: "Calories: 70 per egg, Protein: 6g, Fat: 5g",
      sku: "EGG001",
      productType: "Eggs"
    },
    {
      name: "White Eggs - 12 Pack",
      description: "Regular white eggs for daily cooking",
      inStock: true,
      price: 85,
      quantity: 50,
      weight: "12 eggs",
      brand: "Daily Eggs",
      ingredients: "100% Natural eggs",
      nutritionalInfo: "Calories: 70 per egg, Protein: 6g, Fat: 5g",
      sku: "EGG002",
      productType: "Eggs"
    },
    {
      name: "Organic Free-Range Eggs",
      description: "Premium organic eggs from free-range hens",
      inStock: true,
      price: 120,
      quantity: 25,
      weight: "6 eggs",
      brand: "Organic Farm",
      ingredients: "100% Organic eggs",
      nutritionalInfo: "Calories: 70 per egg, Protein: 6g, Fat: 5g",
      sku: "EGG003",
      productType: "Eggs"
    },
    {
      name: "Omega-3 Enriched Eggs",
      description: "Eggs enriched with heart-healthy Omega-3",
      inStock: true,
      price: 99,
      quantity: 30,
      weight: "6 eggs",
      brand: "Health Plus",
      ingredients: "Omega-3 enriched eggs",
      nutritionalInfo: "Calories: 70 per egg, Protein: 6g, Omega-3: 150mg",
      sku: "EGG004",
      productType: "Eggs"
    },
    {
      name: "Quail Eggs",
      description: "Delicate quail eggs for gourmet recipes",
      inStock: true,
      price: 69,
      quantity: 20,
      weight: "12 eggs",
      brand: "Gourmet Choice",
      ingredients: "100% Quail eggs",
      nutritionalInfo: "Calories: 14 per egg, Protein: 1g",
      sku: "EGG005",
      productType: "Eggs"
    }
  ],
  milk: [
    {
      name: "Full Cream Milk",
      description: "Rich and creamy fresh milk",
      inStock: true,
      price: 60,
      quantity: 100,
      weight: "1L",
      brand: "Pure Dairy",
      ingredients: "Pasteurized milk",
      nutritionalInfo: "Calories: 150 per 240ml, Protein: 8g, Fat: 8g",
      sku: "MLK001",
      productType: "Milk"
    },
    {
      name: "Toned Milk",
      description: "Low-fat milk for health conscious consumers",
      inStock: true,
      price: 55,
      quantity: 120,
      weight: "1L",
      brand: "Healthy Dairy",
      ingredients: "Pasteurized toned milk",
      nutritionalInfo: "Calories: 100 per 240ml, Protein: 8g, Fat: 3g",
      sku: "MLK002",
      productType: "Milk"
    },
    {
      name: "Double Toned Milk",
      description: "Very low-fat milk for weight watchers",
      inStock: true,
      price: 52,
      quantity: 80,
      weight: "1L",
      brand: "Slim Milk",
      ingredients: "Pasteurized double toned milk",
      nutritionalInfo: "Calories: 80 per 240ml, Protein: 8g, Fat: 1.5g",
      sku: "MLK003",
      productType: "Milk"
    },
    {
      name: "Lactose-Free Milk",
      description: "Special milk for lactose intolerant individuals",
      inStock: true,
      price: 89,
      quantity: 35,
      weight: "1L",
      brand: "Care Dairy",
      ingredients: "Lactose-free milk",
      nutritionalInfo: "Calories: 130 per 240ml, Protein: 8g, Fat: 5g",
      sku: "MLK004",
      productType: "Milk"
    },
    {
      name: "Flavored Milk - Chocolate",
      description: "Delicious chocolate flavored milk",
      inStock: true,
      price: 40,
      quantity: 60,
      weight: "200ml",
      brand: "Choco Delight",
      ingredients: "Milk, sugar, cocoa, stabilizers",
      nutritionalInfo: "Calories: 160 per 200ml, Protein: 6g, Sugar: 20g",
      sku: "MLK005",
      productType: "Milk"
    }
  ],
  paneer_tofu: [
    {
      name: "Fresh Paneer",
      description: "Soft and fresh cottage cheese for Indian recipes",
      inStock: true,
      price: 120,
      quantity: 40,
      weight: "200g",
      brand: "Pure Paneer",
      ingredients: "Fresh milk, citric acid",
      nutritionalInfo: "Calories: 265 per 100g, Protein: 18g, Fat: 20g",
      sku: "PNR001",
      productType: "Paneer"
    },
    {
      name: "Low Fat Paneer",
      description: "Paneer made from skimmed milk for health conscious",
      inStock: true,
      price: 130,
      quantity: 30,
      weight: "200g",
      brand: "Fit Choice",
      ingredients: "Skimmed milk, citric acid",
      nutritionalInfo: "Calories: 200 per 100g, Protein: 20g, Fat: 12g",
      sku: "PNR002",
      productType: "Paneer"
    },
    {
      name: "Firm Tofu",
      description: "High protein tofu for Asian and fusion cuisine",
      inStock: true,
      price: 99,
      quantity: 25,
      weight: "200g",
      brand: "Soy Fresh",
      ingredients: "Soybeans, water, coagulant",
      nutritionalInfo: "Calories: 144 per 100g, Protein: 17g, Fat: 9g",
      sku: "TFU001",
      productType: "Tofu"
    },
    {
      name: "Silken Tofu",
      description: "Smooth textured tofu for desserts and smoothies",
      inStock: true,
      price: 89,
      quantity: 20,
      weight: "300g",
      brand: "Silky Soy",
      ingredients: "Soybeans, water, coagulant",
      nutritionalInfo: "Calories: 55 per 100g, Protein: 5g, Fat: 3g",
      sku: "TFU002",
      productType: "Tofu"
    },
    {
      name: "Organic Paneer",
      description: "Paneer made from organic milk",
      inStock: true,
      price: 160,
      quantity: 15,
      weight: "200g",
      brand: "Organic Dairy",
      ingredients: "Organic milk, natural citric acid",
      nutritionalInfo: "Calories: 265 per 100g, Protein: 18g, Fat: 20g",
      sku: "PNR003",
      productType: "Paneer"
    }
  ]
};

async function addProductsToCategory(categoryGroup, categoryItem) {
  const products = productTemplates[categoryItem] || [];
  
  if (products.length === 0) {
    console.log(`No products defined for ${categoryItem}`);
    return;
  }
  
  console.log(`Adding products to ${categoryGroup}/${categoryItem}`);
  
  for (const product of products) {
    try {
      // Add the product to the Firestore collection
      const docRef = await addDoc(collection(db, 'products', categoryGroup, 'items', categoryItem, 'products'), {
        ...product,
        createdAt: new Date(),
        updatedAt: new Date(),
        categoryGroup: categoryGroup,
        categoryItem: categoryItem
      });
      
      // Generate the image path
      const imagePath = `gs://profit-grocery.firebasestorage.app/products/${categoryGroup}/${categoryItem}/${docRef.id}/image.png`;
      
      // Update the document with the image path
      await updateDoc(docRef, {
        imagePath: imagePath
      });
      
      console.log(`  ✓ Added: ${product.name} (ID: ${docRef.id})`);
      console.log(`    Image path: ${imagePath}`);
      
    } catch (error) {
      console.error(`  ✗ Error adding ${product.name}:`, error);
    }
  }
}

async function populateDairyCategory() {
  const categoryGroup = 'dairy_bread';
  
  console.log(`\nPopulating products for category group: ${categoryGroup}`);
  console.log('='.repeat(50));
  
  try {
    // Get all items under this category
    const itemsSnapshot = await getDocs(collection(db, 'categories', categoryGroup, 'items'));
    
    for (const itemDoc of itemsSnapshot.docs) {
      const categoryItem = itemDoc.id;
      await addProductsToCategory(categoryGroup, categoryItem);
    }
    
    console.log('\n='.repeat(50));
    console.log('Finished populating products for', categoryGroup);
    
  } catch (error) {
    console.error('Error populating category:', error);
  }
}

// Run the script
populateDairyCategory().then(() => {
  console.log('\nAll done!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
