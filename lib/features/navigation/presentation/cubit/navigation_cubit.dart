import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  static const int homeTab = 0;
  static const int storeTab = 1;
  static const int builderTab = 2;
  static const int laptopsTab = 3;
  static const int accountTab = 4;

  void select(int index) {
    if (index < 0 || index > 4 || index == state) return;
    emit(index);
  }

  void goHome() => select(homeTab);

  void goToBuilder() => select(builderTab);
}
