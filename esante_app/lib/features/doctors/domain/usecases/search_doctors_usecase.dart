import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/doctor_repository.dart';

class SearchDoctorsUseCase
    implements UseCase<DoctorSearchResult, SearchDoctorsParams> {
  final DoctorRepository repository;

  SearchDoctorsUseCase(this.repository);

  @override
  Future<Either<Failure, DoctorSearchResult>> call(
      SearchDoctorsParams params) {
    return repository.searchDoctors(
      specialty: params.specialty,
      name: params.name,
      city: params.city,
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
      page: params.page,
      limit: params.limit,
    );
  }
}

class SearchDoctorsParams extends Equatable {
  final String? specialty;
  final String? name;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double radius;
  final int page;
  final int limit;

  const SearchDoctorsParams({
    this.specialty,
    this.name,
    this.city,
    this.latitude,
    this.longitude,
    this.radius = 10,
    this.page = 1,
    this.limit = 20,
  });

  SearchDoctorsParams copyWith({
    String? specialty,
    String? name,
    String? city,
    double? latitude,
    double? longitude,
    double? radius,
    int? page,
    int? limit,
  }) {
    return SearchDoctorsParams(
      specialty: specialty ?? this.specialty,
      name: name ?? this.name,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props =>
      [specialty, name, city, latitude, longitude, radius, page, limit];
}
