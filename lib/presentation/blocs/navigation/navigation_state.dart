import 'package:equatable/equatable.dart';

class NavigationState extends Equatable {
  final int currentTabIndex;

  const NavigationState({this.currentTabIndex = 0});

  NavigationState copyWith({int? currentTabIndex}) {
    return NavigationState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
    );
  }

  @override
  List<Object> get props => [currentTabIndex];
}
