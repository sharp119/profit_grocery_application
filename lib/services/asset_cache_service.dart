import 'dart:collection';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A service for caching asset images to improve performance and reliability.
class AssetCacheService {
  static final AssetCacheService _instance = AssetCacheService._internal();
  
  // Singleton pattern
  factory AssetCacheService() => _instance;
  AssetCacheService._internal();
  
  // LRU cache for asset image data
  final LinkedHashMap<String, ui.Image> _imageCache = LinkedHashMap();
  
  // Maximum number of images to keep in the cache
  static const int _maxCacheSize = 50;
  
  // Status of initialization
  bool _isInitialized = false;
  final Set<String> _preloadedAssets = {};
  
  /// Initialize the service and preload essential assets
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Preload essential assets (e.g., category images, app logo, etc.)
      await preloadAssets([
        'assets/categories/1.png',
        'assets/categories/2.png',
        'assets/categories/3.png',
        'assets/categories/4.png',
        'assets/categories/5.png',
        // Add product images that are likely to be used in cart
        'assets/products/1.png',
        'assets/products/2.png',
        'assets/products/3.png',
        'assets/products/4.png',
        'assets/products/5.png',
      ]);
      
      _isInitialized = true;
      print('AssetCacheService: Initialized successfully with ${_preloadedAssets.length} preloaded assets');
    } catch (e) {
      print('AssetCacheService: Error during initialization - $e');
    }
  }
  
  /// Preload a list of assets into the cache
  Future<void> preloadAssets(List<String> assetPaths) async {
    for (final path in assetPaths) {
      await cacheAsset(path);
    }
  }
  
  /// Cache a single asset
  Future<void> cacheAsset(String assetPath) async {
    try {
      if (_imageCache.containsKey(assetPath) || _preloadedAssets.contains(assetPath)) {
        return; // Already cached
      }
      
      // Load the asset data
      final ByteData data = await rootBundle.load(assetPath);
      
      // Mark asset as preloaded
      _preloadedAssets.add(assetPath);
      
      // We don't need to decode the image here, just ensure it's in the asset bundle cache
      print('AssetCacheService: Preloaded $assetPath');
    } catch (e) {
      print('AssetCacheService: Error caching asset $assetPath - $e');
      // Don't throw - just log the error
    }
  }
  
  /// Get a cached image or load it if not cached
  Future<ui.Image?> getImage(String assetPath) async {
    try {
      // Check if the image is already in the cache
      if (_imageCache.containsKey(assetPath)) {
        // Move to the end of the LRU cache (most recently used)
        final image = _imageCache.remove(assetPath);
        _imageCache[assetPath] = image!;
        return image;
      }
      
      // Load the asset
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Add to cache, evict oldest if needed
      if (_imageCache.length >= _maxCacheSize) {
        _imageCache.remove(_imageCache.keys.first);
      }
      _imageCache[assetPath] = image;
      
      return image;
    } catch (e) {
      print('AssetCacheService: Error loading image $assetPath - $e');
      return null;
    }
  }
  
  /// Check if an asset exists
  Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Clear the entire cache
  void clearCache() {
    _imageCache.clear();
  }
  
  /// Remove a specific asset from the cache
  void removeFromCache(String assetPath) {
    _imageCache.remove(assetPath);
  }
}