import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';
import 'package:medical_app/features/ratings/domain/repositories/rating_repository.dart';

class GetDoctorRatingsUseCase {
  final RatingRepository repository;

  GetDoctorRatingsUseCase(this.repository);

  Future<Either<Failure, List<DoctorRatingEntity>>> call(String doctorId) async {
    return await repository.getDoctorRatings(doctorId);
  }
} 