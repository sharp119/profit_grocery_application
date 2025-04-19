import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryItemFirestore {
  final String id;
  final String label;
  final String imagePath;
  final String? description;

  CategoryItemFirestore({
    required this.id,
    required this.label,
    required this.imagePath,
    this.description,
  });

  factory CategoryItemFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryItemFirestore(
      id: doc.id,
      label: data['label'] ?? '',
      imagePath: data['imagePath'] ?? '',
      description: data['description'],
    );
  }
}

class CategoryGroupFirestore {
  final String id;
  final String title;
  final Color backgroundColor;
  final Color itemBackgroundColor;
  final List<CategoryItemFirestore> items;

  CategoryGroupFirestore({
    required this.id,
    required this.title,
    required this.backgroundColor,
    required this.itemBackgroundColor,
    required this.items,
  });

  factory CategoryGroupFirestore.fromFirestore(DocumentSnapshot doc, List<CategoryItemFirestore> items) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryGroupFirestore(
      id: doc.id,
      title: data['title'] ?? '',
      backgroundColor: Color(data['backgroundColor'] as int),
      itemBackgroundColor: Color(data['itemBackgroundColor'] as int),
      items: items,
    );
  }
} 