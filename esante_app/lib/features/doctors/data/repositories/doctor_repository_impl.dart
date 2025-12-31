import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../datasources/doctor_remote_datasource.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl({required this.remoteDataSource});

  /// Map exceptions to appropriate Failure types
  Failure _mapExceptionToFailure(dynamic e) {
    if (e is ServerException) {
      if (e is NetworkException) {
        return const NetworkFailure();
      }
      if (e.code == 'VALIDATION_ERROR' && e.details != null) {
        final errors = (e.details['errors'] as List<dynamic>?)
                ?.map((err) => FieldError(
                      field: err['field'] ?? '',
                      message: err['message'] ?? '',
                    ))
                .toList() ??
            [];
        return ValidationFailure(message: e.message, errors: errors);
      }
      return ServerFailure(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
    return ServerFailure(
      code: 'UNKNOWN_ERROR',
      message: e.toString(),
    );
  }

  @override
  Future<Either<Failure, DoctorSearchResult>> searchDoctors({
    String? specialty,
    String? name,
    String? city,
    double? latitude,
    double? longitude,
    double radius = 10,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await remoteDataSource.searchDoctors(
        specialty: specialty,
        name: name,
        city: city,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        page: page,
        limit: limit,
      );

      return Right(DoctorSearchResult(
        doctors: response.doctors,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        totalDoctors: response.totalDoctors,
      ));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, DoctorSearchResult>> getNearbyDoctors({
    required double latitude,
    required double longitude,
    double radius = 5,
    String? specialty,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await remoteDataSource.getNearbyDoctors(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        specialty: specialty,
        page: page,
        limit: limit,
      );

      return Right(DoctorSearchResult(
        doctors: response.doctors,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        totalDoctors: response.totalDoctors,
      ));
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, DoctorEntity>> getDoctorById(String doctorId) async {
    try {
      final doctor = await remoteDataSource.getDoctorById(doctorId);
      return Right(doctor);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }
}
