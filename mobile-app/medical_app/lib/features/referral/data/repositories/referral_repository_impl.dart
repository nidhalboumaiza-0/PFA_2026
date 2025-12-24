import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/referral/data/datasources/referral_remote_data_source.dart';
import 'package:medical_app/features/referral/domain/entities/referral_entity.dart';
import 'package:medical_app/features/referral/domain/repositories/referral_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SharedPreferences sharedPreferences;

  static const String _tokenKey = 'auth_token';

  ReferralRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.sharedPreferences,
  });

  String? _getToken() {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<Either<Failure, ReferralEntity>> createReferral({
    required String targetDoctorId,
    required String patientId,
    required String reason,
    required String specialty,
    String urgency = 'routine',
    String? diagnosis,
    List<String>? symptoms,
    String? relevantHistory,
    String? currentMedications,
    String? specificConcerns,
    List<String>? attachedDocuments,
    bool includeFullHistory = true,
    List<DateTime>? preferredDates,
    String? referralNotes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.createReferral(
        token: token,
        targetDoctorId: targetDoctorId,
        patientId: patientId,
        reason: reason,
        specialty: specialty,
        urgency: urgency,
        diagnosis: diagnosis,
        symptoms: symptoms,
        relevantHistory: relevantHistory,
        currentMedications: currentMedications,
        specificConcerns: specificConcerns,
        attachedDocuments: attachedDocuments,
        includeFullHistory: includeFullHistory,
        preferredDates: preferredDates,
        referralNotes: referralNotes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> getReferralById(String referralId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getReferralById(
        token: token,
        referralId: referralId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MedecinEntity>>> searchSpecialists({
    required String specialty,
    String? city,
    String? name,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.searchSpecialists(
        token: token,
        specialty: specialty,
        city: city,
        name: name,
      );
      // MedecinModel extends MedecinEntity so we can upcast
      return Right(List<MedecinEntity>.from(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> bookAppointmentForReferral({
    required String referralId,
    required String appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      await remoteDataSource.bookAppointmentForReferral(
        token: token,
        referralId: referralId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        notes: notes,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReferralEntity>>> getSentReferrals({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getSentReferrals(
        token: token,
        status: status,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReferralEntity>>> getReceivedReferrals({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getReceivedReferrals(
        token: token,
        status: status,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> acceptReferral({
    required String referralId,
    String? responseNotes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.acceptReferral(
        token: token,
        referralId: referralId,
        responseNotes: responseNotes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> rejectReferral({
    required String referralId,
    required String reason,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.rejectReferral(
        token: token,
        referralId: referralId,
        reason: reason,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> completeReferral({
    required String referralId,
    String? completionNotes,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.completeReferral(
        token: token,
        referralId: referralId,
        completionNotes: completionNotes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> cancelReferral({
    required String referralId,
    required String reason,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.cancelReferral(
        token: token,
        referralId: referralId,
        reason: reason,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReferralEntity>>> getMyReferrals({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getMyReferrals(
        token: token,
        status: status,
        page: page,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getReferralStatistics() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    final token = _getToken();
    if (token == null) {
      return const Left(AuthFailure('Not authenticated'));
    }

    try {
      final result = await remoteDataSource.getReferralStatistics(token: token);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
