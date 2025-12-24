import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ratings/domain/repositories/rating_repository.dart';

class GetDoctorAverageRatingUseCase {
  final RatingRepository repository;

  GetDoctorAverageRatingUseCase(this.repository);

  Future<Either<Failure, double>> call(String doctorId) async {
    return await repository.getDoctorAverageRating(doctorId);
  }
} 