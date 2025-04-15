import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigateToTabEvent extends NavigationEvent {
  final int tabIndex;

  const NavigateToTabEvent(this.tabIndex);

  @override
  List<Object> get props => [tabIndex];
}
