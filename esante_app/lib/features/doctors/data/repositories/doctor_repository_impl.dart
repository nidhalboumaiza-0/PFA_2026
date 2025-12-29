import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../datasources/doctor_remote_datasource.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl({required this.remoteDataSource});

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
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
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
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DoctorEntity>> getDoctorById(String doctorId) async {
    try {
      final doctor = await remoteDataSource.getDoctorById(doctorId);
      return Right(doctor);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }
}
