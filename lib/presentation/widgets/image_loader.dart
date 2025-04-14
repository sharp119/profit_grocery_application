import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/asset_cache_service.dart';

enum ImageSourceType {
  asset,
  network,
  file,
}

class ImageLoader extends StatelessWidget {
  final String imagePath;
  final ImageSourceType sourceType;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget? placeholder;
  final Widget? errorWidget;

  ImageLoader({
    Key? key,
    required this.imagePath,
    this.sourceType = ImageSourceType.asset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.colorBlendMode,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key) {
    // Preload asset if it's an asset image
    if (sourceType == ImageSourceType.asset) {
      AssetCacheService().cacheAsset(imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default placeholder and error widgets
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade800,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
          ),
        ),
      ),
    );

    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Colors.grey.shade900,
      child: Icon(
        Icons.image_not_supported,
        color: Colors.white.withOpacity(0.5),
        size: (width != null && height != null) ? (width! + height!) / 6 : 24,
      ),
    );

    final actualPlaceholder = placeholder ?? defaultPlaceholder;
    final actualErrorWidget = errorWidget ?? defaultErrorWidget;

    // If borderRadius is specified, wrap image in ClipRRect
    final imageWidget = _buildImageBasedOnSource(
      actualPlaceholder, 
      actualErrorWidget
    );

    if (borderRadius != null && borderRadius! > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildImageBasedOnSource(Widget placeholderWidget, Widget errorWidget) {
    switch (sourceType) {
      case ImageSourceType.network:
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: colorBlendMode,
          placeholder: (context, url) => placeholderWidget,
          errorWidget: (context, url, error) => errorWidget,
        );
      
      case ImageSourceType.asset:
        try {
          // Define possible fallback paths to try in order
          final List<String> pathsToTry = [
            imagePath,
            // Try with explicit assets/ prefix if not already present
            if (!imagePath.startsWith('assets/')) 'assets/$imagePath',
            
            // Try with common subdirectories if the image doesn't have a path
            if (!imagePath.contains('/')) ...[
              'assets/products/$imagePath',
              'assets/categories/$imagePath',
              'assets/images/$imagePath',
              'assets/subcategories/$imagePath',
            ],
            
            // Try with different image extensions if no extension in path
            if (!imagePath.contains('.')) ...[
              '$imagePath.png',
              '$imagePath.jpg',
              'assets/$imagePath.png',
              'assets/$imagePath.jpg',
            ],
          ];
          
          // Keep track of the current path being tried
          String currentPath = pathsToTry.first;
          
          // Return an image widget with custom error handling that tries each path
          return Image.asset(
            currentPath,
            fit: fit,
            width: width,
            height: height,
            color: color,
            colorBlendMode: colorBlendMode,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              } else {
                return placeholderWidget;
              }
            },
            errorBuilder: (context, error, stackTrace) {
              // Get the next path to try
              int currentIndex = pathsToTry.indexOf(currentPath);
              if (currentIndex < pathsToTry.length - 1) {
                // Try the next path
                currentPath = pathsToTry[currentIndex + 1];
                print('Trying alternative path: $currentPath');
                
                return Image.asset(
                  currentPath,
                  fit: fit,
                  width: width,
                  height: height,
                  color: color,
                  colorBlendMode: colorBlendMode,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      return child;
                    } else {
                      return placeholderWidget;
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // If we've tried all paths, show error widget
                    print('All fallback paths failed for image: $imagePath');
                    return errorWidget;
                  },
                );
              }
              
              print('Error loading asset image: $error for path: $imagePath');
              return errorWidget;
            },
          );
        } catch (e) {
          print('Exception in asset image loading: $e');
          return errorWidget;
        }
      
      case ImageSourceType.file:
        // For safety, we'll use a try-catch with Image.asset as fallback
        try {
          return Image.asset(
            imagePath, 
            fit: fit,
            width: width,
            height: height,
            color: color,
            colorBlendMode: colorBlendMode,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading file image: $error');
              return errorWidget;
            },
          );
        } catch (e) {
          print('Exception in file image loading: $e');
          return errorWidget;
        }
      
      default:
        return errorWidget;
    }
  }

  /// Helper factory method to create an asset image
  factory ImageLoader.asset(
    String assetPath, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    double? borderRadius,
    Color? color,
    BlendMode? colorBlendMode,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Normalize the asset path to ensure it starts with 'assets/'
    String normalizedPath = assetPath;
    
    // If path doesn't start with 'assets/' and doesn't have a different explicit directory
    if (!normalizedPath.startsWith('assets/') && !normalizedPath.contains('/')) {
      normalizedPath = 'assets/$normalizedPath';
    }
    
    // Further normalize - check for common asset subdirectories
    if (!normalizedPath.contains('/')) {
      // Try to detect what kind of asset this might be based on naming patterns
      if (normalizedPath.contains('product')) {
        normalizedPath = 'assets/products/$normalizedPath';
      } else if (normalizedPath.contains('cat')) {
        normalizedPath = 'assets/categories/$normalizedPath';
      }
    }
    
    try {
      // Try to preload the asset with the normalized path
      AssetCacheService().cacheAsset(normalizedPath);
    } catch (e) {
      print('Error preloading asset: $e for path: $normalizedPath');
    }
    
    return ImageLoader(
      imagePath: normalizedPath,
      sourceType: ImageSourceType.asset,
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
      color: color,
      colorBlendMode: colorBlendMode,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  /// Helper factory method to create a network image
  factory ImageLoader.network(
    String url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    double? borderRadius,
    Color? color,
    BlendMode? colorBlendMode,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ImageLoader(
      imagePath: url,
      sourceType: ImageSourceType.network,
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
      color: color,
      colorBlendMode: colorBlendMode,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
