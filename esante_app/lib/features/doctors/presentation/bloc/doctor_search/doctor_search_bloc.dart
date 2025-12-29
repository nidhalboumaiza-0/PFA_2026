import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/doctor_entity.dart';
import '../../../domain/usecases/search_doctors_usecase.dart';

part 'doctor_search_event.dart';
part 'doctor_search_state.dart';

class DoctorSearchBloc extends Bloc<DoctorSearchEvent, DoctorSearchState> {
  final SearchDoctorsUseCase searchDoctorsUseCase;

  // Current search params for pagination
  SearchDoctorsParams _currentParams = const SearchDoctorsParams();

  DoctorSearchBloc({
    required this.searchDoctorsUseCase,
  }) : super(DoctorSearchInitial()) {
    on<SearchDoctors>(_onSearchDoctors);
    on<LoadMoreDoctors>(_onLoadMoreDoctors);
    on<UpdateSearchFilters>(_onUpdateSearchFilters);
    on<ClearSearch>(_onClearSearch);
    on<GetCurrentLocation>(_onGetCurrentLocation);
  }

  Future<void> _onSearchDoctors(
    SearchDoctors event,
    Emitter<DoctorSearchState> emit,
  ) async {
    emit(DoctorSearchLoading());

    _currentParams = SearchDoctorsParams(
      specialty: event.specialty,
      name: event.name,
      city: event.city,
      latitude: event.latitude,
      longitude: event.longitude,
      radius: event.radius,
      page: 1,
      limit: 20,
    );

    final result = await searchDoctorsUseCase(_currentParams);

    result.fold(
      (failure) => emit(DoctorSearchError(message: failure.message)),
      (searchResult) => emit(DoctorSearchLoaded(
        doctors: searchResult.doctors,
        hasMore: searchResult.hasMore,
        currentPage: searchResult.currentPage,
        totalDoctors: searchResult.totalDoctors,
        currentFilters: _currentParams,
      )),
    );
  }

  Future<void> _onLoadMoreDoctors(
    LoadMoreDoctors event,
    Emitter<DoctorSearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DoctorSearchLoaded || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    _currentParams = _currentParams.copyWith(page: currentState.currentPage + 1);

    final result = await searchDoctorsUseCase(_currentParams);

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (searchResult) => emit(currentState.copyWith(
        doctors: [...currentState.doctors, ...searchResult.doctors],
        hasMore: searchResult.hasMore,
        currentPage: searchResult.currentPage,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onUpdateSearchFilters(
    UpdateSearchFilters event,
    Emitter<DoctorSearchState> emit,
  ) async {
    add(SearchDoctors(
      specialty: event.specialty,
      name: event.name,
      city: event.city,
      latitude: event.latitude ?? _currentParams.latitude,
      longitude: event.longitude ?? _currentParams.longitude,
      radius: event.radius ?? _currentParams.radius,
    ));
  }

  void _onClearSearch(
    ClearSearch event,
    Emitter<DoctorSearchState> emit,
  ) {
    _currentParams = const SearchDoctorsParams();
    emit(DoctorSearchInitial());
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<DoctorSearchState> emit,
  ) async {
    emit(DoctorSearchLoading());

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const DoctorSearchError(message: 'Location permission denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(const DoctorSearchError(
            message: 'Location permission permanently denied'));
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      emit(LocationObtained(
        latitude: position.latitude,
        longitude: position.longitude,
      ));

      // Automatically search with location
      add(SearchDoctors(
        latitude: position.latitude,
        longitude: position.longitude,
        specialty: event.specialty,
      ));
    } catch (e) {
      emit(DoctorSearchError(message: 'Failed to get location: $e'));
    }
  }
}
