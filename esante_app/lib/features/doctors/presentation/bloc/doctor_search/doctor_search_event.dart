part of 'doctor_search_bloc.dart';

abstract class DoctorSearchEvent extends Equatable {
  const DoctorSearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchDoctors extends DoctorSearchEvent {
  final String? specialty;
  final String? name;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double radius;

  const SearchDoctors({
    this.specialty,
    this.name,
    this.city,
    this.latitude,
    this.longitude,
    this.radius = 10,
  });

  @override
  List<Object?> get props => [specialty, name, city, latitude, longitude, radius];
}

class LoadMoreDoctors extends DoctorSearchEvent {
  const LoadMoreDoctors();
}

class UpdateSearchFilters extends DoctorSearchEvent {
  final String? specialty;
  final String? name;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double? radius;

  const UpdateSearchFilters({
    this.specialty,
    this.name,
    this.city,
    this.latitude,
    this.longitude,
    this.radius,
  });

  @override
  List<Object?> get props => [specialty, name, city, latitude, longitude, radius];
}

class ClearSearch extends DoctorSearchEvent {
  const ClearSearch();
}

class GetCurrentLocation extends DoctorSearchEvent {
  final String? specialty;

  const GetCurrentLocation({this.specialty});

  @override
  List<Object?> get props => [specialty];
}
