import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

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
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.login(email, password);
        await localDataSource.cacheUser(userModel);
        return Right(userModel);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on UnauthorizedException {
        return Left(UnauthorizedFailure());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
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
        await localDataSource.clearCachedUser();
        return Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      // We can still clear local cache and consider it a success
      await localDataSource.clearCachedUser();
      return Right(unit);
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      // First check local storage
      final hasCachedUser = await localDataSource.hasUserCached();

      if (!hasCachedUser) {
        return Right(false);
      }

      // If connected, verify with remote
      if (await networkInfo.isConnected) {
        final isLoggedIn = await remoteDataSource.isLoggedIn();
        if (!isLoggedIn) {
          // If not logged in remotely, clear local cache
          await localDataSource.clearCachedUser();
        }
        return Right(isLoggedIn);
      } else {
        // If offline, trust the local cache
        return Right(true);
      }
    } on CacheException {
      return Right(false);
    } catch (_) {
      return Right(false);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      // First try to get from remote if connected
      if (await networkInfo.isConnected) {
        final remoteUser = await remoteDataSource.getCurrentUser();
        if (remoteUser != null) {
          // Update local cache with latest data
          await localDataSource.cacheUser(remoteUser);
          return Right(remoteUser);
        }
      }

      // If remote fails or offline, try local cache
      final localUser = await localDataSource.getCachedUser();
      return Right(localUser);
    } on CacheException {
      return Left(CacheFailure(message: 'No user found in cache'));
    } on ServerException catch (e) {
      // Try local cache as fallback
      try {
        final localUser = await localDataSource.getCachedUser();
        return Right(localUser);
      } on CacheException {
        return Left(ServerFailure(message: e.message));
      }
    }
  }
}
