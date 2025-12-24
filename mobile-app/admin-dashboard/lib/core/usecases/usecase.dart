import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

// This is a generic UseCase interface for use cases that don't need parameters
abstract class UseCase<Type> {
  Future<Either<Failure, Type>> call();
}

// This is a generic UseCase interface that takes parameters
abstract class UseCaseWithParams<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// This is an empty class for use cases that don't need parameters
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
