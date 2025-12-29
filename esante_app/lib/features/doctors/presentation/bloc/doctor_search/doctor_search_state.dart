part of 'doctor_search_bloc.dart';

abstract class DoctorSearchState extends Equatable {
  const DoctorSearchState();

  @override
  List<Object?> get props => [];
}

class DoctorSearchInitial extends DoctorSearchState {}

class DoctorSearchLoading extends DoctorSearchState {}

class LocationObtained extends DoctorSearchState {
  final double latitude;
  final double longitude;

  const LocationObtained({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class DoctorSearchLoaded extends DoctorSearchState {
  final List<DoctorEntity> doctors;
  final bool hasMore;
  final int currentPage;
  final int totalDoctors;
  final bool isLoadingMore;
  final SearchDoctorsParams currentFilters;

  const DoctorSearchLoaded({
    required this.doctors,
    required this.hasMore,
    required this.currentPage,
    required this.totalDoctors,
    this.isLoadingMore = false,
    required this.currentFilters,
  });

  DoctorSearchLoaded copyWith({
    List<DoctorEntity>? doctors,
    bool? hasMore,
    int? currentPage,
    int? totalDoctors,
    bool? isLoadingMore,
    SearchDoctorsParams? currentFilters,
  }) {
    return DoctorSearchLoaded(
      doctors: doctors ?? this.doctors,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalDoctors: totalDoctors ?? this.totalDoctors,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentFilters: currentFilters ?? this.currentFilters,
    );
  }

  @override
  List<Object?> get props =>
      [doctors, hasMore, currentPage, totalDoctors, isLoadingMore, currentFilters];
}

class DoctorSearchError extends DoctorSearchState {
  final String message;

  const DoctorSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}
