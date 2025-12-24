import '../error/failures.dart';

String mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return (failure as ServerFailure).message ??
          'Server error occurred. Please try again.';
    case CacheFailure:
      return (failure as CacheFailure).message ??
          'Cache error occurred. Please try again.';
    case OfflineFailure:
      return 'Please check your internet connection.';
    case AuthFailure:
      return (failure as AuthFailure).message;
    case UnauthorizedFailure:
      return 'You are not authorized to perform this action.';
    case NotFoundFailure:
      return (failure as NotFoundFailure).message;
    default:
      return 'Unexpected error occurred. Please try again later.';
  }
}
