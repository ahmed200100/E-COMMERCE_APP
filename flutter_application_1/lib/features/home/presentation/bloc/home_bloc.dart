import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_entities.dart';
import '../../domain/usecases/get_home.dart';

sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}

final class HomeNextPageRequested extends HomeEvent {
  const HomeNextPageRequested();
}

final class HomeWishlistToggled extends HomeEvent {
  const HomeWishlistToggled(this.productId);

  final String productId;
}

enum HomeStatus { initial, loading, success, failure }

final class HomeState {
  const HomeState({
    this.status = HomeStatus.initial,
    this.content,
    this.errorMessage,
    this.isLoadingMore = false,
  });

  final HomeStatus status;
  final HomeContent? content;
  final String? errorMessage;
  final bool isLoadingMore;

  HomeState copyWith({
    HomeStatus? status,
    HomeContent? content,
    String? errorMessage,
    bool clearError = false,
    bool? isLoadingMore,
  }) => HomeState(
    status: status ?? this.status,
    content: content ?? this.content,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getHome) : super(const HomeState()) {
    on<HomeStarted>((event, emit) => _loadFirstPage(emit));
    on<HomeRefreshed>((event, emit) => _loadFirstPage(emit));
    on<HomeNextPageRequested>(_loadNextPage);
    on<HomeWishlistToggled>(_toggleWishlist);
  }

  final GetHome _getHome;

  Future<void> _loadFirstPage(Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    final result = await _getHome(page: 1);
    result.fold(
      onSuccess: (content) =>
          emit(HomeState(status: HomeStatus.success, content: content)),
      onFailure: (failure) => emit(
        HomeState(status: HomeStatus.failure, errorMessage: failure.message),
      ),
    );
  }

  Future<void> _loadNextPage(
    HomeNextPageRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = state.content;
    if (current == null || !current.hasNextPage || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getHome(page: current.page + 1);
    result.fold(
      onSuccess: (nextPage) => emit(
        state.copyWith(
          content: current.copyWith(
            featuredProducts: [
              ...current.featuredProducts,
              ...nextPage.featuredProducts,
            ],
            page: nextPage.page,
            hasNextPage: nextPage.hasNextPage,
          ),
          isLoadingMore: false,
        ),
      ),
      onFailure: (failure) => emit(
        state.copyWith(errorMessage: failure.message, isLoadingMore: false),
      ),
    );
  }

  void _toggleWishlist(HomeWishlistToggled event, Emitter<HomeState> emit) {
    final current = state.content;
    if (current == null) return;
    final products = current.featuredProducts
        .map(
          (product) => product.id == event.productId
              ? product.copyWith(isWishlisted: !product.isWishlisted)
              : product,
        )
        .toList(growable: false);
    emit(state.copyWith(content: current.copyWith(featuredProducts: products)));
  }
}
