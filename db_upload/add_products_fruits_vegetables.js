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

// Product templates for different fruits & vegetables categories
const productTemplates = {
  cut_fruits: [
    {
      name: "Fruit Salad Mix",
      description: "Fresh mix of watermelon, papaya, pineapple, and pomegranate",
      inStock: true,
      price: 89,
      quantity: 25,
      weight: "200g",
      brand: "Fresh Cuts",
      ingredients: "Watermelon, Papaya, Pineapple, Pomegranate",
      nutritionalInfo: "Calories: 95 per serving, Vitamin C: 60% DV",
      sku: "CTF001",
      productType: "Cut Fruits"
    },
    {
      name: "Diced Pineapple",
      description: "Juicy and sweet pineapple chunks ready to eat",
      inStock: true,
      price: 69,
      quantity: 30,
      weight: "200g",
      brand: "Tropical Fresh",
      ingredients: "Fresh pineapple",
      nutritionalInfo: "Calories: 83 per serving, Vitamin C: 131% DV",
      sku: "CTF002",
      productType: "Cut Fruits"
    },
    {
      name: "Watermelon Cubes",
      description: "Refreshing seedless watermelon cut into perfect cubes",
      inStock: true,
      price: 49,
      quantity: 40,
      weight: "300g",
      brand: "Summer Fresh",
      ingredients: "Fresh watermelon",
      nutritionalInfo: "Calories: 46 per serving, Vitamin A: 18% DV",
      sku: "CTF003",
      productType: "Cut Fruits"
    },
    {
      name: "Mixed Berries",
      description: "Antioxidant-rich mix of strawberries, blueberries, and raspberries",
      inStock: true,
      price: 149,
      quantity: 15,
      weight: "150g",
      brand: "Berry Delight",
      ingredients: "Strawberries, Blueberries, Raspberries",
      nutritionalInfo: "Calories: 70 per serving, Fiber: 8g",
      sku: "CTF004",
      productType: "Cut Fruits"
    },
    {
      name: "Coconut Slices",
      description: "Fresh coconut meat sliced for immediate consumption",
      inStock: true,
      price: 59,
      quantity: 20,
      weight: "100g",
      brand: "Coco Fresh",
      ingredients: "Fresh coconut",
      nutritionalInfo: "Calories: 354 per 100g, Fiber: 9g",
      sku: "CTF005",
      productType: "Cut Fruits"
    }
  ],
  cut_vegetables: [
    {
      name: "Salad Mix",
      description: "Mixed lettuce, cucumber, tomato, and carrot ready for salad",
      inStock: true,
      price: 69,
      quantity: 35,
      weight: "250g",
      brand: "Salad Ready",
      ingredients: "Lettuce, Cucumber, Tomato, Carrot",
      nutritionalInfo: "Calories: 45 per serving, Fiber: 3g",
      sku: "CTV001",
      productType: "Cut Vegetables"
    },
    {
      name: "Chopped Onions",
      description: "Pre-chopped onions for convenient cooking",
      inStock: true,
      price: 39,
      quantity: 50,
      weight: "200g",
      brand: "Quick Cook",
      ingredients: "Fresh onions",
      nutritionalInfo: "Calories: 40 per 100g",
      sku: "CTV002",
      productType: "Cut Vegetables"
    },
    {
      name: "Diced Vegetables Mix",
      description: "Mix of potato, carrot, and beans diced for curry preparation",
      inStock: true,
      price: 79,
      quantity: 30,
      weight: "500g",
      brand: "Curry Ready",
      ingredients: "Potato, Carrot, French Beans",
      nutritionalInfo: "Calories: 70 per 100g",
      sku: "CTV003",
      productType: "Cut Vegetables"
    },
    {
      name: "Stir Fry Vegetable Mix",
      description: "Julienned bell peppers, broccoli, and baby corn",
      inStock: true,
      price: 99,
      quantity: 25,
      weight: "300g",
      brand: "Wok Fresh",
      ingredients: "Bell peppers, Broccoli, Baby corn",
      nutritionalInfo: "Calories: 35 per 100g",
      sku: "CTV004",
      productType: "Cut Vegetables"
    },
    {
      name: "Grated Coconut",
      description: "Freshly grated coconut for Indian recipes",
      inStock: true,
      price: 49,
      quantity: 40,
      weight: "100g",
      brand: "Coco Grate",
      ingredients: "Fresh coconut",
      nutritionalInfo: "Calories: 354 per 100g",
      sku: "CTV005",
      productType: "Cut Vegetables"
    }
  ],
  exotic_fruits: [
    {
      name: "Dragon Fruit",
      description: "Exotic dragon fruit with vibrant pink skin and white flesh",
      inStock: true,
      price: 149,
      quantity: 20,
      weight: "1 pc (approx 400g)",
      brand: "Exotic Harvest",
      ingredients: "Fresh dragon fruit",
      nutritionalInfo: "Calories: 60 per 100g, Fiber: 3g",
      sku: "EXF001",
      productType: "Exotic Fruits"
    },
    {
      name: "Kiwi",
      description: "New Zealand kiwi fruits rich in Vitamin C",
      inStock: true,
      price: 199,
      quantity: 30,
      weight: "3 pcs",
      brand: "Kiwi Fresh",
      ingredients: "Fresh kiwi",
      nutritionalInfo: "Calories: 61 per 100g, Vitamin C: 93mg",
      sku: "EXF002",
      productType: "Exotic Fruits"
    },
    {
      name: "Avocado",
      description: "Creamy Mexican avocados perfect for guacamole",
      inStock: true,
      price: 249,
      quantity: 25,
      weight: "2 pcs",
      brand: "Avo Fresh",
      ingredients: "Fresh avocado",
      nutritionalInfo: "Calories: 160 per 100g, Healthy fats: 15g",
      sku: "EXF003",
      productType: "Exotic Fruits"
    },
    {
      name: "Passion Fruit",
      description: "Aromatic passion fruits with tangy pulp",
      inStock: true,
      price: 179,
      quantity: 15,
      weight: "4 pcs",
      brand: "Passion Harvest",
      ingredients: "Fresh passion fruit",
      nutritionalInfo: "Calories: 97 per 100g, Vitamin C: 30mg",
      sku: "EXF004",
      productType: "Exotic Fruits"
    },
    {
      name: "Thai Guava",
      description: "Sweet and crunchy Thai guava variety",
      inStock: true,
      price: 89,
      quantity: 35,
      weight: "500g",
      brand: "Thai Fresh",
      ingredients: "Fresh Thai guava",
      nutritionalInfo: "Calories: 68 per 100g, Vitamin C: 228mg",
      sku: "EXF005",
      productType: "Exotic Fruits"
    }
  ],
  exotic_vegetables: [
    {
      name: "Zucchini",
      description: "Fresh green zucchini for continental dishes",
      inStock: true,
      price: 99,
      quantity: 30,
      weight: "500g",
      brand: "Continental Fresh",
      ingredients: "Fresh zucchini",
      nutritionalInfo: "Calories: 17 per 100g, Fiber: 1g",
      sku: "EXV001",
      productType: "Exotic Vegetables"
    },
    {
      name: "Broccoli",
      description: "Premium quality broccoli florets",
      inStock: true,
      price: 129,
      quantity: 25,
      weight: "300g",
      brand: "Green Valley",
      ingredients: "Fresh broccoli",
      nutritionalInfo: "Calories: 34 per 100g, Vitamin C: 89mg",
      sku: "EXV002",
      productType: "Exotic Vegetables"
    },
    {
      name: "Red Cabbage",
      description: "Purple cabbage for salads and cooking",
      inStock: true,
      price: 79,
      quantity: 20,
      weight: "400g",
      brand: "Color Fresh",
      ingredients: "Fresh red cabbage",
      nutritionalInfo: "Calories: 31 per 100g, Vitamin C: 57mg",
      sku: "EXV003",
      productType: "Exotic Vegetables"
    },
    {
      name: "Asparagus",
      description: "Tender green asparagus spears",
      inStock: true,
      price: 249,
      quantity: 15,
      weight: "250g",
      brand: "Gourmet Fresh",
      ingredients: "Fresh asparagus",
      nutritionalInfo: "Calories: 20 per 100g, Fiber: 2.1g",
      sku: "EXV004",
      productType: "Exotic Vegetables"
    },
    {
      name: "Cherry Tomatoes",
      description: "Sweet and juicy cherry tomatoes",
      inStock: true,
      price: 109,
      quantity: 35,
      weight: "200g",
      brand: "Cherry Delight",
      ingredients: "Fresh cherry tomatoes",
      nutritionalInfo: "Calories: 18 per 100g, Vitamin C: 14mg",
      sku: "EXV005",
      productType: "Exotic Vegetables"
    }
  ],
  fresh_fruits: [
    {
      name: "Bananas",
      description: "Fresh yellow bananas rich in potassium",
      inStock: true,
      price: 49,
      quantity: 100,
      weight: "6 pcs",
      brand: "Nature's Best",
      ingredients: "Fresh bananas",
      nutritionalInfo: "Calories: 89 per 100g, Potassium: 358mg",
      sku: "FRF001",
      productType: "Fresh Fruits"
    },
    {
      name: "Apples - Red",
      description: "Sweet and crunchy red apples",
      inStock: true,
      price: 129,
      quantity: 50,
      weight: "1 kg",
      brand: "Orchard Fresh",
      ingredients: "Fresh apples",
      nutritionalInfo: "Calories: 52 per 100g, Fiber: 2.4g",
      sku: "FRF002",
      productType: "Fresh Fruits"
    },
    {
      name: "Oranges",
      description: "Juicy oranges packed with Vitamin C",
      inStock: true,
      price: 89,
      quantity: 60,
      weight: "1 kg",
      brand: "Citrus Farm",
      ingredients: "Fresh oranges",
      nutritionalInfo: "Calories: 47 per 100g, Vitamin C: 53mg",
      sku: "FRF003",
      productType: "Fresh Fruits"
    },
    {
      name: "Grapes - Green",
      description: "Sweet seedless green grapes",
      inStock: true,
      price: 159,
      quantity: 30,
      weight: "500g",
      brand: "Vineyard Fresh",
      ingredients: "Fresh grapes",
      nutritionalInfo: "Calories: 69 per 100g, Vitamin K: 14.6mcg",
      sku: "FRF004",
      productType: "Fresh Fruits"
    },
    {
      name: "Pomegranate",
      description: "Ruby red pomegranates with juicy arils",
      inStock: true,
      price: 199,
      quantity: 25,
      weight: "4 pcs (approx 1 kg)",
      brand: "Ruby Fresh",
      ingredients: "Fresh pomegranate",
      nutritionalInfo: "Calories: 83 per 100g, Fiber: 4g",
      sku: "FRF005",
      productType: "Fresh Fruits"
    }
  ],
  fresh_vegetables: [
    {
      name: "Tomatoes",
      description: "Fresh red tomatoes for salads and cooking",
      inStock: true,
      price: 39,
      quantity: 80,
      weight: "1 kg",
      brand: "Farm Fresh",
      ingredients: "Fresh tomatoes",
      nutritionalInfo: "Calories: 18 per 100g, Vitamin C: 14mg",
      sku: "FRV001",
      productType: "Fresh Vegetables"
    },
    {
      name: "Potatoes",
      description: "Versatile potatoes for all cooking needs",
      inStock: true,
      price: 29,
      quantity: 100,
      weight: "1 kg",
      brand: "Potato Farm",
      ingredients: "Fresh potatoes",
      nutritionalInfo: "Calories: 77 per 100g, Carbs: 17g",
      sku: "FRV002",
      productType: "Fresh Vegetables"
    },
    {
      name: "Onions",
      description: "Fresh onions essential for Indian cooking",
      inStock: true,
      price: 35,
      quantity: 90,
      weight: "1 kg",
      brand: "Kitchen Essential",
      ingredients: "Fresh onions",
      nutritionalInfo: "Calories: 40 per 100g, Fiber: 1.7g",
      sku: "FRV003",
      productType: "Fresh Vegetables"
    },
    {
      name: "Carrots",
      description: "Fresh orange carrots rich in beta-carotene",
      inStock: true,
      price: 49,
      quantity: 50,
      weight: "500g",
      brand: "Beta Fresh",
      ingredients: "Fresh carrots",
      nutritionalInfo: "Calories: 41 per 100g, Vitamin A: 835mcg",
      sku: "FRV004",
      productType: "Fresh Vegetables"
    },
    {
      name: "Green Beans",
      description: "Tender green beans for everyday cooking",
      inStock: true,
      price: 59,
      quantity: 40,
      weight: "500g",
      brand: "Green Valley",
      ingredients: "Fresh green beans",
      nutritionalInfo: "Calories: 31 per 100g, Fiber: 3.4g",
      sku: "FRV005",
      productType: "Fresh Vegetables"
    }
  ],
  herbs_seasonings: [
    {
      name: "Fresh Coriander",
      description: "Aromatic coriander leaves for garnishing",
      inStock: true,
      price: 19,
      quantity: 100,
      weight: "100g",
      brand: "Herb Garden",
      ingredients: "Fresh coriander",
      nutritionalInfo: "Calories: 23 per 100g, Vitamin C: 27mg",
      sku: "HRB001",
      productType: "Herbs"
    },
    {
      name: "Mint Leaves",
      description: "Fresh mint for chutneys and beverages",
      inStock: true,
      price: 25,
      quantity: 80,
      weight: "100g",
      brand: "Fresh Mint",
      ingredients: "Fresh mint",
      nutritionalInfo: "Calories: 44 per 100g, Vitamin A: 212mcg",
      sku: "HRB002",
      productType: "Herbs"
    },
    {
      name: "Curry Leaves",
      description: "Fresh curry leaves for authentic Indian flavor",
      inStock: true,
      price: 15,
      quantity: 90,
      weight: "50g",
      brand: "Indian Herbs",
      ingredients: "Fresh curry leaves",
      nutritionalInfo: "Calories: 108 per 100g, Iron: 0.93mg",
      sku: "HRB003",
      productType: "Herbs"
    },
    {
      name: "Basil",
      description: "Fresh basil leaves for Italian cuisine",
      inStock: true,
      price: 49,
      quantity: 40,
      weight: "50g",
      brand: "Mediterranean Fresh",
      ingredients: "Fresh basil",
      nutritionalInfo: "Calories: 23 per 100g, Vitamin K: 415mcg",
      sku: "HRB004",
      productType: "Herbs"
    },
    {
      name: "Ginger",
      description: "Fresh ginger root for cooking and tea",
      inStock: true,
      price: 39,
      quantity: 70,
      weight: "250g",
      brand: "Root Fresh",
      ingredients: "Fresh ginger",
      nutritionalInfo: "Calories: 80 per 100g, Potassium: 415mg",
      sku: "HRB005",
      productType: "Seasonings"
    }
  ],
  organic: [
    {
      name: "Organic Tomatoes",
      description: "Certified organic tomatoes grown without chemicals",
      inStock: true,
      price: 69,
      quantity: 30,
      weight: "500g",
      brand: "Organic Farm",
      ingredients: "Organic tomatoes",
      nutritionalInfo: "Calories: 18 per 100g, Vitamin C: 14mg",
      sku: "ORG001",
      productType: "Organic Vegetables"
    },
    {
      name: "Organic Spinach",
      description: "Fresh organic spinach leaves for healthy eating",
      inStock: true,
      price: 49,
      quantity: 40,
      weight: "250g",
      brand: "Green Organic",
      ingredients: "Organic spinach",
      nutritionalInfo: "Calories: 23 per 100g, Iron: 2.7mg",
      sku: "ORG002",
      productType: "Organic Vegetables"
    },
    {
      name: "Organic Apples",
      description: "Chemical-free apples with natural sweetness",
      inStock: true,
      price: 199,
      quantity: 25,
      weight: "1 kg",
      brand: "Nature's Organic",
      ingredients: "Organic apples",
      nutritionalInfo: "Calories: 52 per 100g, Fiber: 2.4g",
      sku: "ORG003",
      productType: "Organic Fruits"
    },
    {
      name: "Organic Carrots",
      description: "Sweet and crunchy organic carrots",
      inStock: true,
      price: 79,
      quantity: 35,
      weight: "500g",
      brand: "Organic Harvest",
      ingredients: "Organic carrots",
      nutritionalInfo: "Calories: 41 per 100g, Vitamin A: 835mcg",
      sku: "ORG004",
      productType: "Organic Vegetables"
    },
    {
      name: "Organic Banana",
      description: "Naturally grown organic bananas",
      inStock: true,
      price: 89,
      quantity: 45,
      weight: "6 pcs",
      brand: "Eco Fruits",
      ingredients: "Organic bananas",
      nutritionalInfo: "Calories: 89 per 100g, Potassium: 358mg",
      sku: "ORG005",
      productType: "Organic Fruits"
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

async function populateFruitsVegetablesCategory() {
  const categoryGroup = 'fruits_vegetables';
  
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
populateFruitsVegetablesCategory().then(() => {
  console.log('\nAll done!');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});
