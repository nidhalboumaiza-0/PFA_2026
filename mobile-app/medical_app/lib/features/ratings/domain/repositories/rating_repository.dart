import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';

abstract class RatingRepository {
  /// Submit a rating for a doctor
  Future<Either<Failure, Unit>> submitDoctorRating(DoctorRatingEntity rating);

  /// Get all ratings for a specific doctor
  Future<Either<Failure, List<DoctorRatingEntity>>> getDoctorRatings(
    String doctorId,
  );

  /// Get average rating for a doctor
  Future<Either<Failure, double>> getDoctorAverageRating(String doctorId);

  /// Check if patient has already rated a specific appointment
  Future<Either<Failure, bool>> hasPatientRatedAppointment(
    String patientId,
    String rendezVousId,
  );
}
