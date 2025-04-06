import 'package:equatable/equatable.dart';

import '../../../domain/entities/product.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

class RefreshHomeData extends HomeEvent {
  const RefreshHomeData();
}

class SelectCategoryTab extends HomeEvent {
  final int tabIndex;

  const SelectCategoryTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class UpdateCartQuantity extends HomeEvent {
  final Product product;
  final int quantity;

  const UpdateCartQuantity(this.product, this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}