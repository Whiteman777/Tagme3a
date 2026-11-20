import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/home_feed.dart';
import '../../../../core/presentation/load_status.dart';

class HomeState extends Equatable {
  const HomeState({
    this.status = LoadStatus.initial,
    this.feed,
    this.errorMessage,
    this.isRefreshing = false,
  });

  final LoadStatus status;
  final HomeFeed? feed;
  final String? errorMessage;
  final bool isRefreshing;

  HomeState copyWith({
    LoadStatus? status,
    HomeFeed? feed,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return HomeState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, feed, errorMessage, isRefreshing];
}
