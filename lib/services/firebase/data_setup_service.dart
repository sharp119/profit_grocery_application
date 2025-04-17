import 'package:flutter/material.dart';
import 'package:profit_grocery_application/data/models/category_group_model.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';
import 'package:profit_grocery_application/services/firebase/firebase_storage_service.dart';
import 'package:profit_grocery_application/services/firebase/firestore_service.dart';
import 'package:profit_grocery_application/services/logging_service.dart';

class DataSetupService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  // Singleton pattern
  static final DataSetupService _instance = DataSetupService._internal();
  factory DataSetupService() => _instance;
  DataSetupService._internal();
  
  // Status trackers
  bool _isSettingUp = false;
  int _totalTasks = 0;
  int _completedTasks = 0;
  String _currentTask = '';
  
  // Status getters
  bool get isSettingUp => _isSettingUp;
  double get progress => _totalTasks > 0 ? _completedTasks / _totalTasks : 0.0;
  String get currentTask => _currentTask;
  
  // Status callbacks
  Function(String)? onTaskUpdate;
  Function(double)? onProgressUpdate;
  Function(bool, String)? onSetupComplete;
  
  void _updateTask(String task) {
    _currentTask = task;
    if (onTaskUpdate != null) {
      onTaskUpdate!(task);
    }
  }
  
  void _updateProgress() {
    _completedTasks++;
    if (onProgressUpdate != null) {
      onProgressUpdate!(progress);
    }
  }
  
  /// Set up all product and category data in Firebase
  Future<void> setupFirebaseData() async {
    if (_isSettingUp) {
      return;
    }
    
    try {
      _isSettingUp = true;
      _completedTasks = 0;
      
      // Calculate total tasks
      _totalTasks = CategoryGroups.all.length; // Category groups
      for (final group in CategoryGroups.all) {
        _totalTasks += group.items.length; // Category items
        _totalTasks += group.items.length * 6; // 6 products per category item
      }
      
      // 1. Set up category groups and items
      await _setupCategoryGroups();
      
      // 2. Set up products
      await _setupProducts();
      
      // Notify completion
      if (onSetupComplete != null) {
        onSetupComplete!(true, 'Firebase data setup completed successfully');
      }
    } catch (e) {
      LoggingService.logError('DataSetupService', 'Error setting up Firebase data: $e');
      if (onSetupComplete != null) {
        onSetupComplete!(false, 'Error setting up Firebase data: $e');
      }
    } finally {
      _isSettingUp = false;
    }
  }
  
  /// Set up category groups and items in Firebase
  Future<void> _setupCategoryGroups() async {
    _updateTask('Setting up category groups...');
    
    for (final categoryGroup in CategoryGroups.all) {
      _updateTask('Setting up ${categoryGroup.title} category group...');
      
      // Check if the category group already exists
      final exists = await _firestoreService.categoryGroupExists(categoryGroup.id);
      if (!exists) {
        // Upload category group to Firestore
        await _firestoreService.addCategoryGroup(categoryGroup);
      }
      
      _updateProgress();
      
      // Upload category item images and update Firestore paths
      for (final categoryItem in categoryGroup.items) {
        _updateTask('Setting up ${categoryItem.label} category item...');
        
        // Extract the original image name from the path
        final imageName = categoryItem.imagePath.split('/').last;
        final assetPath = 'assets/subcategories/$imageName';
        
        // Upload the image to Firebase Storage
        final downloadUrl = await _storageService.uploadCategoryImage(
          assetPath: assetPath,
          categoryGroupId: categoryGroup.id,
          categoryItemId: categoryItem.id,
        );
        
        // Update the image path in Firestore
        await _firestoreService.updateCategoryItemImagePath(
          categoryGroupId: categoryGroup.id,
          categoryItemId: categoryItem.id,
          imagePath: downloadUrl,
        );
        
        _updateProgress();
      }
    }
  }
  
  /// Set up products in Firebase
  Future<void> _setupProducts() async {
    _updateTask('Setting up products...');
    
    // Sample descriptions for different category groups
    final Map<String, List<String>> descriptions = {
      'grocery_kitchen': [
        'Fresh and organic, sourced directly from local farms.',
        'Premium quality, packed with essential nutrients.',
        'Handpicked and carefully sorted for the best quality.',
        'Pure and natural, free from harmful additives.',
        'Certified organic product, grown without pesticides.',
        'Essential kitchen staple, perfect for everyday cooking.',
      ],
      'snacks_drinks': [
        'Crunchy and flavorful, perfect for snacking.',
        'Refreshing and energizing, best served chilled.',
        'Delicious blend of authentic flavors.',
        'Handcrafted recipe with premium ingredients.',
        'No artificial flavors or preservatives added.',
        'Perfect companion for movies and gatherings.',
      ],
      'beauty_personal_care': [
        'Gentle formula suitable for all skin types.',
        'Enriched with natural extracts and vitamins.',
        'Dermatologically tested and approved.',
        'Alcohol-free and non-drying formula.',
        'Paraben-free and cruelty-free product.',
        'Provides all-day protection and nourishment.',
      ],
      'fruits_vegetables': [
        'Farm fresh, harvested at peak ripeness.',
        'Locally grown, reducing carbon footprint.',
        'Rich in essential vitamins and minerals.',
        'Naturally sweet and flavorful.',
        'Carefully sorted and graded for quality.',
        'Perfect addition to healthy meals.',
      ],
      'dairy_bread': [
        'Made from 100% pure cow\'s milk.',
        'Rich and creamy texture, full of flavor.',
        'Freshly baked using traditional methods.',
        'High in calcium and protein.',
        'No artificial additives or preservatives.',
        'Sourced from local dairy farms.',
      ],
      'bakeries_biscuits': [
        'Baked fresh daily using traditional recipes.',
        'Perfect blend of crispness and flavor.',
        'Made with real butter for authentic taste.',
        'No artificial flavors or colors added.',
        'Great with tea or coffee, anytime snack.',
        'Carefully packaged to maintain freshness.',
      ],
    };
    
    // Sample brands for different category groups
    final Map<String, List<String>> brands = {
      'grocery_kitchen': [
        'NatureFresh', 'OrganicValley', 'FarmDirect', 'PurePantry', 'GreenHarvest', 'EcoEssentials'
      ],
      'snacks_drinks': [
        'CrunchMaster', 'SnackDelight', 'FlavorFusion', 'MunchBox', 'TastyTreats', 'SnackSavvy'
      ],
      'beauty_personal_care': [
        'NaturGlow', 'PureEssence', 'DermaCare', 'VitalRadiance', 'SkinNurture', 'GentleCare'
      ],
      'fruits_vegetables': [
        'FreshHarvest', 'NaturesBounty', 'GardenFresh', 'OrganicFarms', 'EarthYield', 'VitaminGreens'
      ],
      'dairy_bread': [
        'PureMilk', 'DairyDelight', 'CreamyCow', 'FreshLoaf', 'WheatMaster', 'BakersDawn'
      ],
      'bakeries_biscuits': [
        'CrumbKing', 'BakeryDelight', 'CookieCraze', 'SweetBites', 'GoldenBake', 'CrispyCrunch'
      ],
    };
    
    // Sample weights/sizes for different category groups
    final Map<String, List<String>> weights = {
      'grocery_kitchen': [
        '500g', '1kg', '250g', '750g', '2kg', '100g'
      ],
      'snacks_drinks': [
        '150g', '200g', '500ml', '1L', '330ml', '80g'
      ],
      'beauty_personal_care': [
        '200ml', '100ml', '150ml', '50g', '75g', '250ml'
      ],
      'fruits_vegetables': [
        '1kg', '500g', '250g', '2kg', '750g', '4kg'
      ],
      'dairy_bread': [
        '500ml', '1L', '400g', '200g', '6pcs', '12pcs'
      ],
      'bakeries_biscuits': [
        '250g', '150g', '300g', '100g', '500g', '8pcs'
      ],
    };
    
    for (final categoryGroup in CategoryGroups.all) {
      for (final categoryItem in categoryGroup.items) {
        _updateTask('Setting up products for ${categoryItem.label}...');
        
        // Get sample descriptions, brands, and weights for this category group
        final categoryDescriptions = descriptions[categoryGroup.id] ?? descriptions['grocery_kitchen']!;
        final categoryBrands = brands[categoryGroup.id] ?? brands['grocery_kitchen']!;
        final categoryWeights = weights[categoryGroup.id] ?? weights['grocery_kitchen']!;
        
        // Create 6 products for each category item
        for (int i = 0; i < 6; i++) {
          final productName = '${categoryItem.label} ${i + 1}';
          final price = (50 + (i * 25) + (DateTime.now().millisecondsSinceEpoch % 50)).toDouble();
          final mrp = price * 1.2; // 20% markup for MRP
          
          // Create a product with empty ID - will be auto-generated
          final product = ProductModel(
            id: '',
            name: productName,
            image: '', // Will be updated after upload
            description: categoryDescriptions[i],
            price: price,
            mrp: mrp,
            inStock: true,
            categoryId: categoryGroup.id,
            subcategoryId: categoryItem.id,
            tags: [categoryGroup.id, categoryItem.id],
            isFeatured: i < 2, // First 2 products are featured
            isActive: true,
          );
          
          // Add the product to Firestore - this will auto-generate an ID
          final productId = await _firestoreService.addProduct(product);
          
          // Upload a random product image
          final imageUrl = await _storageService.uploadRandomProductImage(
            productId: productId,
            categoryId: categoryGroup.id,
            subcategoryId: categoryItem.id,
          );
          
          // Update the product with the image URL and additional fields
          final updatedProduct = product.copyWith(
            id: productId,
            image: imageUrl,
            weight: categoryWeights[i % categoryWeights.length],
            brand: categoryBrands[i % categoryBrands.length],
            rating: 3.5 + (i % 2), // Ratings between 3.5 and 4.5
            reviewCount: 10 + (i * 5), // Review counts between 10 and 35
          );
          
          await _firestoreService.addProduct(updatedProduct);
          
          _updateProgress();
        }
      }
    }
  }
}