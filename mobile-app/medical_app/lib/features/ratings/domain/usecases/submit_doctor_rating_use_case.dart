import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';
import 'package:medical_app/features/ratings/domain/repositories/rating_repository.dart';

class SubmitDoctorRatingUseCase {
  final RatingRepository repository;

  SubmitDoctorRatingUseCase(this.repository);

  Future<Either<Failure, Unit>> call(DoctorRatingEntity rating) async {
    return await repository.submitDoctorRating(rating);
  }
} 