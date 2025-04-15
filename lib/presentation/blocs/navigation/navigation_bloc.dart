import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/navigation/navigation_event.dart';
import 'package:profit_grocery_application/presentation/blocs/navigation/navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigateToTabEvent>(_onNavigateToTab);
  }

  void _onNavigateToTab(NavigateToTabEvent event, Emitter<NavigationState> emit) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }
}
