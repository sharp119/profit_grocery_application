import 'package:flutter/material.dart';
import 'package:profit_grocery_application/presentation/widgets/grids/horizontal_bestseller_grid.dart';

class OrdersBestsellersSection extends StatefulWidget {
  const OrdersBestsellersSection({Key? key}) : super(key: key);

  @override
  State<OrdersBestsellersSection> createState() => _OrdersBestsellersSectionState();
}

class _OrdersBestsellersSectionState extends State<OrdersBestsellersSection> {
  @override
  Widget build(BuildContext context) {
    return HorizontalBestsellerSection(
      title: 'You May Also Like',
      limit: 6,
      useRealTimeUpdates: true,
      showBestsellerBadge: true,
      onProductTap: (product) {
        print('Bestseller tapped: \\${product.name}');
      },
    );
  }
} 