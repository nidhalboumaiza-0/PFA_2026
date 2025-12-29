import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor_entity.dart';

/// Repository interface for doctor-related operations
abstract class DoctorRepository {
  /// Search doctors by specialty, location, and other filters
  Future<Either<Failure, DoctorSearchResult>> searchDoctors({
    String? specialty,
    String? name,
    String? city,
    double? latitude,
    double? longitude,
    double radius = 10,
    int page = 1,
    int limit = 20,
  });

  /// Get nearby doctors based on coordinates
  Future<Either<Failure, DoctorSearchResult>> getNearbyDoctors({
    required double latitude,
    required double longitude,
    double radius = 5,
    String? specialty,
    int page = 1,
    int limit = 20,
  });

  /// Get doctor details by ID
  Future<Either<Failure, DoctorEntity>> getDoctorById(String doctorId);
}

/// Result wrapper for paginated doctor search
class DoctorSearchResult {
  final List<DoctorEntity> doctors;
  final int currentPage;
  final int totalPages;
  final int totalDoctors;

  const DoctorSearchResult({
    required this.doctors,
    required this.currentPage,
    required this.totalPages,
    required this.totalDoctors,
  });

  bool get hasMore => currentPage < totalPages;
}
