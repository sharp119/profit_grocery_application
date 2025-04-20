import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_theme.dart';

/// Utility for loading images with proper error handling and caching
class ImageLoader {
  /// Load an image from network with caching support
  static Widget network(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Validate URL
    String validUrl = url;
    
    // Check if path is a Firestore storage path
    if (url.startsWith('https://firebasestorage.googleapis.com') == false &&
        url.startsWith('http') == false) {
      // Use a default placeholder image
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade800,
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: (width ?? 100) / 2,
            ),
          );
    }
    
    return CachedNetworkImage(
      imageUrl: validUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ??
          Container(
            width: width,
            height: height,
            color: AppTheme.secondaryColor,
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 2,
              ),
            ),
          ),
      errorWidget: (context, url, error) => errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade800,
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: (width ?? 100) / 2,
            ),
          ),
    );
  }

  /// Load an image from an asset
  static Widget asset(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade800,
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: (width ?? 100) / 2,
          ),
        );
      },
    );
  }
  
  /// Load an image from memory with a fallback to asset
  static Widget memory(
    dynamic bytes, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? assetFallback,
  }) {
    if (bytes == null) {
      return assetFallback != null 
          ? asset(
              assetFallback,
              width: width,
              height: height,
              fit: fit,
            )
          : Container(
              width: width,
              height: height,
              color: Colors.grey.shade800,
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: (width ?? 100) / 2,
              ),
            );
    }
    
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return assetFallback != null 
            ? asset(
                assetFallback,
                width: width,
                height: height,
                fit: fit,
              )
            : Container(
                width: width,
                height: height,
                color: Colors.grey.shade800,
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: (width ?? 100) / 2,
                ),
              );
      },
    );
  }
}