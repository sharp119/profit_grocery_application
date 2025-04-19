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

// Product templates for different grocery & kitchen categories
const productTemplates = {
  atta_rice_dal: [
    {
      name: "Whole Wheat Atta",
      description: "Premium quality whole wheat flour for soft rotis",
      inStock: true,
      price: 220,
      quantity: 50,
      weight: "5 kg",
      brand: "Aashirvaad",
      ingredients: "100% Whole wheat",
      nutritionalInfo: "Calories: 340 per 100g, Protein: 12g, Fiber: 3g",
      sku: "ARD001",
      productType: "Atta"
    },
    {
      name: "Basmati Rice",
      description: "Long grain aromatic basmati rice",
      inStock: true,
      price: 180,
      quantity: 40,
      weight: "1 kg",
      brand: "India Gate",
      ingredients: "Pure basmati rice",
      nutritionalInfo: "Calories: 350 per 100g, Carbs: 78g",
      sku: "ARD002",
      productType: "Rice"
    },
    {
      name: "Toor Dal",
      description: "Premium quality split pigeon peas",
      inStock: true,
      price: 150,
      quantity: 60,
      weight: "1 kg",
      brand: "Tata Sampann",
      ingredients: "Split pigeon peas",
      nutritionalInfo: "Calories: 335 per 100g, Protein: 22g",
      sku: "ARD003",
      productType: "Dal"
    },
    {
      name: "Multigrain Atta",
      description: "Blend of wheat, jowar, bajra, and ragi",
      inStock: true,
      price: 250,
      quantity: 30,
      weight: "2 kg",
      brand: "Nature's Best",
      ingredients: "Wheat, Jowar, Bajra, Ragi",
      nutritionalInfo: "Calories: 320 per 100g, Protein: 15g, Fiber: 8g",
      sku: "ARD004",
      productType: "Atta"
    },
    {
      name: "Sona Masoori Rice",
      description: "Lightweight and aromatic rice variety",
      inStock: true,
      price: 140,
      quantity: 45,
      weight: "5 kg",
      brand: "Daawat",
      ingredients: "Pure sona masoori rice",
      nutritionalInfo: "Calories: 345 per 100g, Carbs: 76g",
      sku: "ARD005",
      productType: "Rice"
    }
  ],
  cleaning_household: [
    {
      name: "Floor Cleaner",
      description: "Antibacterial floor cleaner with fresh fragrance",
      inStock: true,
      price: 189,
      quantity: 40,
      weight: "1 L",
      brand: "Lizol",
      ingredients: "Benzalkonium chloride, fragrance, surfactants",
      nutritionalInfo: "Not applicable for cleaning products",
      sku: "CLN001",
      productType: "Floor Cleaner"
    },
    {
      name: "Dishwashing Liquid",
      description: "Grease-fighting formula with lemon power",
      inStock: true,
      price: 99,
      quantity: 60,
      weight: "500 ml",
      brand: "Vim",
      ingredients: "Surfactants, lemon extract, preservatives",
      nutritionalInfo: "Not applicable for cleaning products",
      sku: "CLN002",
      productType: "Dishwashing"
    },
    {
      name: "Glass Cleaner",
      description: "Streak-free glass and surface cleaner",
      inStock: true,
      price: 89,
      quantity: 50,
      weight: "500 ml",
      brand: "Colin",
      ingredients: "Isopropyl alcohol, ammonia, surfactants",
      nutritionalInfo: "Not applicable for cleaning products",
      sku: "CLN003",
      productType: "Glass Cleaner"
    },
    {
      name: "Toilet Cleaner",
      description: "Powerful disinfectant with stain removal",
      inStock: true,
      price: 109,
      quantity: 45,
      weight: "500 ml",
      brand: "Harpic",
      ingredients: "Hydrochloric acid, surfactants, fragrance",
      nutritionalInfo: "Not applicable for cleaning products",
      sku: "CLN004",
      productType: "Toilet Cleaner"
    },
    {
      name: "Kitchen Wipes",
      description: "Multi-purpose antibacterial kitchen wipes",
      inStock: true,
      price: 129,
      quantity: 35,
      weight: "30 wipes",
      brand: "Scottex",
      ingredients: "Non-woven fabric, cleaning agents",
      nutritionalInfo: "Not applicable for cleaning products",
      sku: "CLN005",
      productType: "Wipes"
    }
  ],
  dry_fruits_cereals: [
    {
      name: "Almonds",
      description: "Premium California almonds rich in nutrients",
      inStock: true,
      price: 799,
      quantity: 25,
      weight: "500 g",
      brand: "Nutraj",
      ingredients: "100% Almonds",
      nutritionalInfo: "Calories: 579 per 100g, Protein: 21g, Fat: 49g",
      sku: "DFC001",
      productType: "Dry Fruits"
    },
    {
      name: "Cashews",
      description: "Whole W320 grade cashew nuts",
      inStock: true,
      price: 699,
      quantity: 30,
      weight: "500 g",
      brand: "Happilo",
      ingredients: "100% Cashews",
      nutritionalInfo: "Calories: 553 per 100g, Protein: 18g, Fat: 44g",
      sku: "DFC002",
      productType: "Dry Fruits"
    },
    {
      name: "Oats",
      description: "Whole grain rolled oats for healthy breakfast",
      inStock: true,
      price: 195,
      quantity: 40,
      weight: "1 kg",
      brand: "Quaker",
      ingredients: "100% Whole grain oats",
      nutritionalInfo: "Calories: 389 per 100g, Protein: 17g, Fiber: 10g",
      sku: "DFC003",
      productType: "Cereals"
    },
    {
      name: "Corn Flakes",
      description: "Crispy corn flakes fortified with vitamins",
      inStock: true,
      price: 165,
      quantity: 35,
      weight: "500 g",
      brand: "Kellogg's",
      ingredients: "Corn, sugar, malt extract, vitamins and minerals",
      nutritionalInfo: "Calories: 378 per 100g, Iron: 28% DV",
      sku: "DFC004",
      productType: "Cereals"
    },
    {
      name: "Mixed Dry Fruits",
      description: "Premium mix of almonds, cashews, raisins, and pistachios",
      inStock: true,
      price: 899,
      quantity: 20,
      weight: "500 g",
      brand: "Carnival",
      ingredients: "Almonds, Cashews, Raisins, Pistachios",
      nutritionalInfo: "Calories: 580 per 100g, Protein: 15g",
      sku: "DFC005",
      productType: "Dry Fruits"
    }
  ],
  instant_food: [
    {
      name: "Instant Noodles",
      description: "Masala flavor instant noodles ready in 2 minutes",
      inStock: true,
      price: 90,
      quantity: 100,
      weight: "280 g (4 x 70g)",
      brand: "Maggi",
      ingredients: "Wheat flour, palm oil, salt, spices",
      nutritionalInfo: "Calories: 315 per serving, Carbs: 45g",
      sku: "INS001",
      productType: "Noodles"
    },
    {
      name: "Ready-to-Eat Dal Makhani",
      description: "Authentic Punjabi dal makhani, just heat and eat",
      inStock: true,
      price: 149,
      quantity: 40,
      weight: "300 g",
      brand: "MTR",
      ingredients: "Black lentils, butter, tomatoes, spices",
      nutritionalInfo: "Calories: 233 per serving, Protein: 8g",
      sku: "INS002",
      productType: "Ready to Eat"
    },
    {
      name: "Instant Idli Mix",
      description: "Just add water for soft and fluffy idlis",
      inStock: true,
      price: 85,
      quantity: 50,
      weight: "500 g",
      brand: "Gits",
      ingredients: "Rice flour, urad dal flour, salt",
      nutritionalInfo: "Calories: 190 per serving, Protein: 4g",
      sku: "INS003",
      productType: "Instant Mix"
    },
    {
      name: "Cup Noodles",
      description: "Spicy chilli garlic cup noodles",
      inStock: true,
      price: 45,
      quantity: 75,
      weight: "70 g",
      brand: "Top Ramen",
      ingredients: "Noodles, seasonings, dehydrated vegetables",
      nutritionalInfo: "Calories: 298 per cup, Carbs: 42g",
      sku: "INS004",
      productType: "Noodles"
    },
    {
      name: "Ready-to-Serve Palak Paneer",
      description: "Restaurant-style palak paneer, heat and serve",
      inStock: true,
      price: 169,
      quantity: 35,
      weight: "300 g",
      brand: "Haldiram's",
      ingredients: "Spinach, cottage cheese, cream, spices",
      nutritionalInfo: "Calories: 220 per serving, Protein: 9g",
      sku: "INS005",
      productType: "Ready to Eat"
    }
  ],
  kitchenware: [
    {
      name: "Non-Stick Frying Pan",
      description: "PFOA-free non-stick pan with induction base",
      inStock: true,
      price: 899,
      quantity: 20,
      weight: "24 cm",
      brand: "Prestige",
      ingredients: "Aluminum body, non-stick coating",
      nutritionalInfo: "Not applicable for kitchenware",
      sku: "KIT001",
      productType: "Cookware"
    },
    {
      name: "Stainless Steel Pressure Cooker",
      description: "3L induction base pressure cooker",
      inStock: true,
      price: 1499,
      quantity: 15,
      weight: "3 L",
      brand: "Hawkins",
      ingredients: "Stainless steel",
      nutritionalInfo: "Not applicable for kitchenware",
      sku: "KIT002",
      productType: "Cookware"
    },
    {
      name: "Kitchen Knife Set",
      description: "5-piece knife set with holder",
      inStock: true,
      price: 699,
      quantity: 25,
      weight: "Set of 5",
      brand: "Wonderchef",
      ingredients: "Stainless steel blades, plastic handles",
      nutritionalInfo: "Not applicable for kitchenware",
      sku: "KIT003",
      productType: "Cutlery"
    },
    {
      name: "Glass Storage Containers",
      description: "Set of 3 airtight glass containers with lids",
      inStock: true,
      price: 549,
      quantity: 30,
      weight: "3 pcs",
      brand: "Borosil",
      ingredients: "Borosilicate glass, BPA-free lids",
      nutritionalInfo: "Not applicable for kitchenware",
      sku: "KIT004",
      productType: "Storage"
    },
    {
      name: "Microwave-Safe Bowls",
      description: "Set of 4 microwave-safe serving bowls",
      inStock: true,
      price: 399,
      quantity: 35,
      weight: "4 pcs",
      brand: "Milton",
      ingredients: "BPA-free plastic",
      nutritionalInfo: "Not applicable for kitchenware",
      sku: "KIT005",
      productType: "Serveware"
    }
  ],
  oil_ghee_masala: [
    {
      name: "Refined Sunflower Oil",
      description: "Heart-healthy sunflower oil for everyday cooking",
      inStock: true,
      price: 180,
      quantity: 70,
      weight: "1 L",
      brand: "Fortune",
      ingredients: "100% Refined sunflower oil",
      nutritionalInfo: "Calories: 884 per 100ml, Fat: 100g",
      sku: "OGM001",
      productType: "Oil"
    },
    {
      name: "Pure Desi Ghee",
      description: "Traditional clarified butter made from cow's milk",
      inStock: true,
      price: 549,
      quantity: 40,
      weight: "1 L",
      brand: "Amul",
      ingredients: "Pure cow milk fat",
      nutritionalInfo: "Calories: 900 per 100g, Fat: 100g",
      sku: "OGM002",
      productType: "Ghee"
    },
    {
      name: "Garam Masala",
      description: "Aromatic blend of ground spices",
      inStock: true,
      price: 85,
      quantity: 100,
      weight: "100 g",
      brand: "MDH",
      ingredients: "Coriander, cumin, cinnamon, cardamom, cloves",
      nutritionalInfo: "Calories: 314 per 100g",
      sku: "OGM003",
      productType: "Masala"
    },
    {
      name: "Olive Oil - Extra Virgin",
      description: "Cold pressed extra virgin olive oil",
      inStock: true,
      price: 749,
      quantity: 25,
      weight: "500 ml",
      brand: "Figaro",
      ingredients: "100% Extra virgin olive oil",
      nutritionalInfo: "Calories: 884 per 100ml, Monounsaturated fat: 73g",
      sku: "OGM004",
      productType: "Oil"
    },
    {
      name: "Chilli Powder",
      description: "Kashmiri red chilli powder for color and mild heat",
      inStock: true,
      price: 149,
      quantity: 80,
      weight: "200 g",
      brand: "Everest",
      ingredients: "100% Ground red chillies",
      nutritionalInfo: "Calories: 282 per 100g",
      sku: "OGM005",
      productType: "Masala"
    }
  ],
  sauces_spreads: [
    {
      name: "Tomato Ketchup",
      description: "Classic tomato ketchup with tangy taste",
      inStock: true,
      price: 120,
      quantity: 60,
      weight: "1 kg",
      brand: "Kissan",
      ingredients: "Tomato paste, sugar, vinegar, spices",
      nutritionalInfo: "Calories: 112 per 100g, Sugar: 25g",
      sku: "SAS001",
      productType: "Sauce"
    },
    {
      name: "Peanut Butter - Crunchy",
      description: "High protein peanut butter with real peanut pieces",
      inStock: true,
      price: 249,
      quantity: 40,
      weight: "340 g",
      brand: "Sundrop",
      ingredients: "Roasted peanuts, sugar, salt",
      nutritionalInfo: "Calories: 588 per 100g, Protein: 25g",
      sku: "SAS002",
      productType: "Spread"
    },
    {
      name: "Mayonnaise",
      description: "Creamy eggless mayonnaise for sandwiches and dips",
      inStock: true,
      price: 169,
      quantity: 50,
      weight: "275 g",
      brand: "Del Monte",
      ingredients: "Vegetable oil, water, vinegar, sugar",
      nutritionalInfo: "Calories: 680 per 100g, Fat: 75g",
      sku: "SAS003",
      productType: "Spread"
    },
    {
      name: "Chilli Sauce",
      description: "Spicy red chilli sauce for Indo-Chinese dishes",
      inStock: true,
      price: 89,
      quantity: 70,
      weight: "200 g",
      brand: "Ching's Secret",
      ingredients: "Red chillies, vinegar, garlic, salt",
      nutritionalInfo: "Calories: 82 per 100g",
      sku: "SAS004",
      productType: "Sauce"
    },
    {
      name: "Mixed Fruit Jam",
      description: "Delicious spread made from real fruit pulp",
      inStock: true,
      price: 155,
      quantity: 45,
      weight: "500 g",
      brand: "Kissan",
      ingredients: "Mixed fruit pulp, sugar, pectin",
      nutritionalInfo: "Calories: 270 per 100g, Sugar: 65g",
      sku: "SAS005",
      productType: "Spread"
    }
  ],
  vegetables_fruits: [
    {
      name: "Frozen Mixed Vegetables",
      description: "Pre-cut mixed vegetables blend for quick cooking",
      inStock: true,
      price: 129,
      quantity: 30,
      weight: "500 g",
      brand: "Safal",
      ingredients: "Carrots, beans, corn, peas",
      nutritionalInfo: "Calories: 70 per 100g, Fiber: 3g",
      sku: "VGF001",
      productType: "Frozen Vegetables"
    },
    {
      name: "Frozen Sweet Corn",
      description: "Premium quality sweet corn kernels",
      inStock: true,
      price: 99,
      quantity: 35,
      weight: "450 g",
      brand: "Mother Dairy",
      ingredients: "100% Sweet corn",
      nutritionalInfo: "Calories: 86 per 100g, Carbs: 19g",
      sku: "VGF002",
      productType: "Frozen Vegetables"
    },
    {
      name: "Dehydrated Onions",
      description: "Ready-to-use dehydrated onion flakes",
      inStock: true,
      price: 79,
      quantity: 50,
      weight: "100 g",
      brand: "Catch",
      ingredients: "100% Dehydrated onions",
      nutritionalInfo: "Calories: 349 per 100g",
      sku: "VGF003",
      productType: "Dehydrated"
    },
    {
      name: "Frozen Green Peas",
      description: "Farm fresh green peas, blanched and frozen",
      inStock: true,
      price: 85,
      quantity: 40,
      weight: "500 g",
      brand: "McCain",
      ingredients: "100% Green peas",
      nutritionalInfo: "Calories: 80 per 100g, Protein: 5g",
      sku: "VGF004",
      productType: "Frozen Vegetables"
    },
    {
      name: "Canned Pineapple Slices",
      description: "Juicy pineapple slices in natural juice",
      inStock: true,
      price: 145,
      quantity: 25,
      weight: "850 g",
      brand: "Del Monte",
      ingredients: "Pineapple, pineapple juice",
      nutritionalInfo: "Calories: 50 per 100g, Vitamin C: 47% DV",
      sku: "VGF005",
      productType: "Canned Fruits"
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

async function populateGroceryKitchenCategory() {
  const categoryGroup = 'grocery_kitchen';
  
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
populateGroceryKitchenCategory().then(() => {
  console.log('\nAll done!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
