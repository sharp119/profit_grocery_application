import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/firestore/category_group_firestore_model.dart';
import '../../../data/repositories/category_repository.dart';

// Events
abstract class CategoriesEvent {}

class LoadCategories extends CategoriesEvent {}

// States
abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<CategoryGroupFirestore> categories;

  CategoriesLoaded(this.categories);
}

class CategoriesError extends CategoriesState {
  final String message;

  CategoriesError(this.message);
}

// BLoC
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoryRepository _repository;

  CategoriesBloc({
    required CategoryRepository repository,
  })  : _repository = repository,
        super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      emit(CategoriesLoading());
      final categories = await _repository.fetchCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
} 