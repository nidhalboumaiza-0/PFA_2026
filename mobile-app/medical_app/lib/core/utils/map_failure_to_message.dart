import '../error/failures.dart';

String mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return (failure as ServerFailure).message; // Access instance getter
    case EmptyCacheFailure:
      return (failure as EmptyCacheFailure).message; // Access instance getter
    case ServerMessageFailure:
      return (failure as ServerMessageFailure).message; // Access instance field
    case UnauthorizedFailure:
      return (failure as UnauthorizedFailure).message; // Access instance field
    case OfflineFailure:
      return (failure as OfflineFailure).message; // Access instance getter
    case AuthFailure:
      return (failure as AuthFailure).message;
    case UsedEmailOrPhoneNumberFailure:
      return (failure as UsedEmailOrPhoneNumberFailure).message;
    case YouHaveToCreateAccountAgainFailure:
      return (failure as YouHaveToCreateAccountAgainFailure).message;
    case TimeoutFailure:
      return (failure as TimeoutFailure).message;
    default:
      return 'An unexpected error occurred'; // Fallback for unhandled cases
  }
}
