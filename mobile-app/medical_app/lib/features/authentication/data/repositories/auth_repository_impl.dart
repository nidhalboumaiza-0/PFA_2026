import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/features/authentication/data/models/medecin_model.dart';
import 'package:medical_app/features/authentication/data/models/patient_model.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';

import '../data sources/auth_local_data_source.dart';
import '../data sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<void> signInWithGoogle() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signInWithGoogle();
      } on AuthException catch (e) {
        throw AuthFailure(e.message);
      } on ServerException catch (e) {
        throw ServerFailure();
      }
    } else {
      throw OfflineFailure();
    }
  }

  @override
  Future<Either<Failure, Unit>> createAccount({
    required UserEntity user,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        UserModel userModel;
          if (user is PatientEntity) {
            userModel = PatientModel(
              id: user.id,
              name: user.name,
              lastName: user.lastName,
              email: user.email,
              role: user.role,
              gender: user.gender,
              phoneNumber: user.phoneNumber,
              dateOfBirth: user.dateOfBirth,
              antecedent: user.antecedent,
              bloodType: user.bloodType,
              height: user.height,
              weight: user.weight,
              allergies: user.allergies,
              chronicDiseases: user.chronicDiseases,
              emergencyContact: user.emergencyContact,
              insuranceInfo: user.insuranceInfo,
              address: user.address,
              location: user.location,
              profilePicture: user.profilePicture,
            );
          } else if (user is MedecinEntity) {
            userModel = MedecinModel(
              id: user.id,
              name: user.name,
              lastName: user.lastName,
              email: user.email,
              role: user.role,
              gender: user.gender,
              phoneNumber: user.phoneNumber,
              dateOfBirth: user.dateOfBirth,
              speciality: user.speciality!,
              numLicence: user.numLicence!,
              appointmentDuration: user.appointmentDuration,
              subSpecialty: user.subSpecialty,
              clinicName: user.clinicName,
              clinicAddress: user.clinicAddress,
              about: user.about,
              languages: user.languages,
              isVerified: user.isVerified,
              acceptsInsurance: user.acceptsInsurance,
              education: user.education,
              experience: user.experience,
              workingHours: user.workingHours,
              averageRating: user.averageRating,
              totalRatings: user.totalRatings,
              consultationFee: user.consultationFee,
              acceptedInsurance: user.acceptedInsurance,
              address: user.address,
              location: user.location,
              profilePicture: user.profilePicture,
            );
          } else {
          return Left(
            AuthFailure('Only patient or doctor accounts can be created'),
          );
        }
        await remoteDataSource.createAccount(userModel, password);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on UsedEmailOrPhoneNumberException catch (e) {
        return Left(UsedEmailOrPhoneNumberFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.login(email, password);
        UserEntity userEntity;
        if (userModel is PatientModel) {
          userEntity = PatientEntity(
            id: userModel.id,
            name: userModel.name,
            lastName: userModel.lastName,
            email: userModel.email,
            role: userModel.role,
            gender: userModel.gender,
            phoneNumber: userModel.phoneNumber,
            dateOfBirth: userModel.dateOfBirth,
            antecedent: userModel.antecedent,
            accountStatus: userModel.accountStatus,
            isEmailVerified: userModel.isEmailVerified,
            isActive: userModel.isActive,
            lastLogin: userModel.lastLogin,
            address: userModel.address,
            location: userModel.location,
            profilePicture: userModel.profilePicture,
            isOnline: userModel.isOnline,
            oneSignalPlayerId: userModel.oneSignalPlayerId,
            passwordResetCode: userModel.passwordResetCode,
            passwordResetExpires: userModel.passwordResetExpires,
            refreshToken: userModel.refreshToken,
            bloodType: userModel.bloodType,
            height: userModel.height,
            weight: userModel.weight,
            allergies: userModel.allergies,
            chronicDiseases: userModel.chronicDiseases,
            emergencyContact: userModel.emergencyContact,
            insuranceInfo: userModel.insuranceInfo,
          );
        } else if (userModel is MedecinModel) {
          userEntity = MedecinEntity(
            id: userModel.id,
            name: userModel.name,
            lastName: userModel.lastName,
            email: userModel.email,
            role: userModel.role,
            gender: userModel.gender,
            phoneNumber: userModel.phoneNumber,
            dateOfBirth: userModel.dateOfBirth,
            speciality: userModel.speciality,
            numLicence: userModel.numLicence,
            appointmentDuration: userModel.appointmentDuration,
            accountStatus: userModel.accountStatus,
            isEmailVerified: userModel.isEmailVerified,
            isActive: userModel.isActive,
            lastLogin: userModel.lastLogin,
            address: userModel.address,
            location: userModel.location,
            profilePicture: userModel.profilePicture,
            isOnline: userModel.isOnline,
            oneSignalPlayerId: userModel.oneSignalPlayerId,
            passwordResetCode: userModel.passwordResetCode,
            passwordResetExpires: userModel.passwordResetExpires,
            refreshToken: userModel.refreshToken,
            subSpecialty: userModel.subSpecialty,
            clinicName: userModel.clinicName,
            clinicAddress: userModel.clinicAddress,
            about: userModel.about,
            languages: userModel.languages,
            isVerified: userModel.isVerified,
            acceptsInsurance: userModel.acceptsInsurance,
            education: userModel.education,
            experience: userModel.experience,
            workingHours: userModel.workingHours,
            averageRating: userModel.averageRating,
            totalRatings: userModel.totalRatings,
            consultationFee: userModel.consultationFee,
            acceptedInsurance: userModel.acceptedInsurance,
          );
        } else {
          userEntity = UserEntity(
            id: userModel.id,
            name: userModel.name,
            lastName: userModel.lastName,
            email: userModel.email,
            role: userModel.role,
            gender: userModel.gender,
            phoneNumber: userModel.phoneNumber,
            dateOfBirth: userModel.dateOfBirth,
            accountStatus: userModel.accountStatus,
            isEmailVerified: userModel.isEmailVerified,
            isActive: userModel.isActive,
            lastLogin: userModel.lastLogin,
            address: userModel.address,
            location: userModel.location,
            profilePicture: userModel.profilePicture,
            isOnline: userModel.isOnline,
            oneSignalPlayerId: userModel.oneSignalPlayerId,
            passwordResetCode: userModel.passwordResetCode,
            passwordResetExpires: userModel.passwordResetExpires,
            refreshToken: userModel.refreshToken,
          );
        }
        return Right(userEntity);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } on UnauthorizedException catch(e) {
        return Left(UnauthorizedFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on YouHaveToCreateAccountAgainException catch (e) {
        return Left(YouHaveToCreateAccountAgainFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logout();
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyEmailWithToken(String token) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyEmailWithToken(token);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> resendVerification(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resendVerification(email);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> forgotPassword(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.forgotPassword(email);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPasswordWithToken(token, newPassword);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.changePassword(currentPassword, newPassword);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on UnauthorizedException {
        return Left(UnauthorizedFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken(String refreshToken) async {
    if (await networkInfo.isConnected) {
      try {
        final newToken = await remoteDataSource.refreshToken(refreshToken);
        return Right(newToken);
      } on ServerException {
        return Left(ServerFailure());
      } on UnauthorizedException {
        return Left(UnauthorizedFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUser(UserEntity user) async {
    if (await networkInfo.isConnected) {
      try {
        UserModel userModel;
        if (user is PatientEntity) {
          userModel = PatientModel(
            id: user.id!,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            antecedent: user.antecedent,
            accountStatus: user.accountStatus,
            isEmailVerified: user.isEmailVerified,
            isActive: user.isActive,
            lastLogin: user.lastLogin,
            address: user.address,
            location: user.location,
            profilePicture: user.profilePicture,
            isOnline: user.isOnline,
            oneSignalPlayerId: user.oneSignalPlayerId,
            passwordResetCode: user.passwordResetCode,
            passwordResetExpires: user.passwordResetExpires,
            refreshToken: user.refreshToken,
            bloodType: user.bloodType,
            height: user.height,
            weight: user.weight,
            allergies: user.allergies,
            chronicDiseases: user.chronicDiseases,
            emergencyContact: user.emergencyContact,
            insuranceInfo: user.insuranceInfo,
          );
        } else if (user is MedecinEntity) {
          userModel = MedecinModel(
            id: user.id!,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            speciality: user.speciality!,
            numLicence: user.numLicence!,
            appointmentDuration: user.appointmentDuration,
            accountStatus: user.accountStatus,
            isEmailVerified: user.isEmailVerified,
            isActive: user.isActive,
            lastLogin: user.lastLogin,
            address: user.address,
            location: user.location,
            profilePicture: user.profilePicture,
            isOnline: user.isOnline,
            oneSignalPlayerId: user.oneSignalPlayerId,
            passwordResetCode: user.passwordResetCode,
            passwordResetExpires: user.passwordResetExpires,
            refreshToken: user.refreshToken,
            subSpecialty: user.subSpecialty,
            clinicName: user.clinicName,
            clinicAddress: user.clinicAddress,
            about: user.about,
            languages: user.languages,
            isVerified: user.isVerified,
            acceptsInsurance: user.acceptsInsurance,
            education: user.education,
            experience: user.experience,
            workingHours: user.workingHours,
            averageRating: user.averageRating,
            totalRatings: user.totalRatings,
            consultationFee: user.consultationFee,
            acceptedInsurance: user.acceptedInsurance,
          );
        } else {
          userModel = UserModel(
            id: user.id!,
            name: user.name,
            lastName: user.lastName,
            email: user.email,
            role: user.role,
            gender: user.gender,
            phoneNumber: user.phoneNumber,
            dateOfBirth: user.dateOfBirth,
            accountStatus: user.accountStatus,
            isEmailVerified: user.isEmailVerified,
            isActive: user.isActive,
            lastLogin: user.lastLogin,
            address: user.address,
            location: user.location,
            profilePicture: user.profilePicture,
            isOnline: user.isOnline,
            oneSignalPlayerId: user.oneSignalPlayerId,
            passwordResetCode: user.passwordResetCode,
            passwordResetExpires: user.passwordResetExpires,
            refreshToken: user.refreshToken,
          );
        }
        await remoteDataSource.updateUser(userModel);
        return const Right(unit);
      } on ServerException {
        return Left(ServerFailure());
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      }
    } else {
      return Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getUser();
      UserEntity userEntity;
      
      if (userModel is PatientModel) {
        userEntity = PatientEntity(
          id: userModel.id,
          name: userModel.name,
          lastName: userModel.lastName,
          email: userModel.email,
          role: userModel.role,
          gender: userModel.gender,
          phoneNumber: userModel.phoneNumber,
          dateOfBirth: userModel.dateOfBirth,
          antecedent: userModel.antecedent,
          accountStatus: userModel.accountStatus,
          isEmailVerified: userModel.isEmailVerified,
          isActive: userModel.isActive,
          lastLogin: userModel.lastLogin,
          address: userModel.address,
          location: userModel.location,
          profilePicture: userModel.profilePicture,
          isOnline: userModel.isOnline,
          oneSignalPlayerId: userModel.oneSignalPlayerId,
          passwordResetCode: userModel.passwordResetCode,
          passwordResetExpires: userModel.passwordResetExpires,
          refreshToken: userModel.refreshToken,
          bloodType: userModel.bloodType,
          height: userModel.height,
          weight: userModel.weight,
          allergies: userModel.allergies,
          chronicDiseases: userModel.chronicDiseases,
          emergencyContact: userModel.emergencyContact,
          insuranceInfo: userModel.insuranceInfo,
        );
      } else if (userModel is MedecinModel) {
        userEntity = MedecinEntity(
          id: userModel.id,
          name: userModel.name,
          lastName: userModel.lastName,
          email: userModel.email,
          role: userModel.role,
          gender: userModel.gender,
          phoneNumber: userModel.phoneNumber,
          dateOfBirth: userModel.dateOfBirth,
          speciality: userModel.speciality,
          numLicence: userModel.numLicence,
          appointmentDuration: userModel.appointmentDuration,
          accountStatus: userModel.accountStatus,
          isEmailVerified: userModel.isEmailVerified,
          isActive: userModel.isActive,
          lastLogin: userModel.lastLogin,
          address: userModel.address,
          location: userModel.location,
          profilePicture: userModel.profilePicture,
          isOnline: userModel.isOnline,
          oneSignalPlayerId: userModel.oneSignalPlayerId,
          passwordResetCode: userModel.passwordResetCode,
          passwordResetExpires: userModel.passwordResetExpires,
          refreshToken: userModel.refreshToken,
          subSpecialty: userModel.subSpecialty,
          clinicName: userModel.clinicName,
          clinicAddress: userModel.clinicAddress,
          about: userModel.about,
          languages: userModel.languages,
          isVerified: userModel.isVerified,
          acceptsInsurance: userModel.acceptsInsurance,
          education: userModel.education,
          experience: userModel.experience,
          workingHours: userModel.workingHours,
          averageRating: userModel.averageRating,
          totalRatings: userModel.totalRatings,
          consultationFee: userModel.consultationFee,
          acceptedInsurance: userModel.acceptedInsurance,
        );
      } else {
        userEntity = UserEntity(
          id: userModel.id,
          name: userModel.name,
          lastName: userModel.lastName,
          email: userModel.email,
          role: userModel.role,
          gender: userModel.gender,
          phoneNumber: userModel.phoneNumber,
          dateOfBirth: userModel.dateOfBirth,
          accountStatus: userModel.accountStatus,
          isEmailVerified: userModel.isEmailVerified,
          isActive: userModel.isActive,
          lastLogin: userModel.lastLogin,
          address: userModel.address,
          location: userModel.location,
          profilePicture: userModel.profilePicture,
          isOnline: userModel.isOnline,
          oneSignalPlayerId: userModel.oneSignalPlayerId,
          passwordResetCode: userModel.passwordResetCode,
          passwordResetExpires: userModel.passwordResetExpires,
          refreshToken: userModel.refreshToken,
        );
      }
      return Right(userEntity);
    } on EmptyCacheException {
      return Left(EmptyCacheFailure());
    } catch (e) {
      return Left(AuthFailure('Failed to get current user: $e'));
    }
  }
}
