import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/profile/data/datasources/user_remote_data_source.dart';
import 'package:medical_app/features/profile/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> getUserProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getUserProfile();
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePatientProfile(PatientModel patient) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePatientProfile(patient);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateDoctorProfile(MedecinModel doctor) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateDoctorProfile(doctor);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on UnauthorizedException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
