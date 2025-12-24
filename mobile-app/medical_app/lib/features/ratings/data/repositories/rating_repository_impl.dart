import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:medical_app/features/ratings/data/models/doctor_rating_model.dart';
import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';
import 'package:medical_app/features/ratings/domain/repositories/rating_repository.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  RatingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Unit>> submitDoctorRating(
    DoctorRatingEntity rating,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final ratingModel = DoctorRatingModel(
          id: rating.id,
          doctorId: rating.doctorId,
          patientId: rating.patientId,
          patientName: rating.patientName,
          rating: rating.rating,
          comment: rating.comment,
          createdAt: rating.createdAt,
          rendezVousId: rating.rendezVousId,
        );
        await remoteDataSource.submitDoctorRating(ratingModel);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<DoctorRatingEntity>>> getDoctorRatings(
    String doctorId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final ratings = await remoteDataSource.getDoctorRatings(doctorId);
        return Right(ratings);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, double>> getDoctorAverageRating(
    String doctorId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final averageRating = await remoteDataSource.getDoctorAverageRating(
          doctorId,
        );
        return Right(averageRating);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasPatientRatedAppointment(
    String patientId,
    String rendezVousId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final hasRated = await remoteDataSource.hasPatientRatedAppointment(
          patientId,
          rendezVousId,
        );
        return Right(hasRated);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(OfflineFailure());
    }
  }
}
