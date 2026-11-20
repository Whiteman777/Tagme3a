import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/load_status.dart';
import '../../domain/usecases/get_home_feed.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required GetHomeFeed getHomeFeed})
    : _getHomeFeed = getHomeFeed,
      super(const HomeState()) {
    on<HomeStarted>((event, emit) => _load(emit));
    on<HomeRefreshRequested>((event, emit) => _load(emit, refresh: true));
  }

  final GetHomeFeed _getHomeFeed;

  Future<void> _load(Emitter<HomeState> emit, {bool refresh = false}) async {
    if (refresh && state.feed != null) {
      emit(state.copyWith(isRefreshing: true, errorMessage: null));
    } else {
      emit(state.copyWith(status: LoadStatus.loading, errorMessage: null));
    }

    try {
      final feed = await _getHomeFeed();
      emit(
        HomeState(status: LoadStatus.success, feed: feed, isRefreshing: false),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: state.feed == null ? LoadStatus.failure : LoadStatus.success,
          isRefreshing: false,
          errorMessage: 'تعذر تحميل الصفحة الرئيسية. حاول مرة أخرى.',
        ),
      );
    }
  }
}
