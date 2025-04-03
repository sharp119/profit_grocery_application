import 'package:equatable/equatable.dart';

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
