import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';
import 'package:medical_app/features/ratings/domain/usecases/get_doctor_average_rating_use_case.dart';
import 'package:medical_app/features/ratings/domain/usecases/get_doctor_ratings_use_case.dart';
import 'package:medical_app/features/ratings/domain/usecases/has_patient_rated_appointment_use_case.dart';
import 'package:medical_app/features/ratings/domain/usecases/submit_doctor_rating_use_case.dart';

part 'rating_event.dart';
part 'rating_state.dart';

class RatingBloc extends Bloc<RatingEvent, RatingState> {
  final SubmitDoctorRatingUseCase submitDoctorRatingUseCase;
  final HasPatientRatedAppointmentUseCase hasPatientRatedAppointmentUseCase;
  final GetDoctorRatingsUseCase getDoctorRatingsUseCase;
  final GetDoctorAverageRatingUseCase getDoctorAverageRatingUseCase;

  RatingBloc({
    required this.submitDoctorRatingUseCase,
    required this.hasPatientRatedAppointmentUseCase,
    required this.getDoctorRatingsUseCase,
    required this.getDoctorAverageRatingUseCase,
  }) : super(RatingInitial()) {
    on<SubmitDoctorRating>(_onSubmitDoctorRating);
    on<CheckPatientRatedAppointment>(_onCheckPatientRatedAppointment);
    on<GetDoctorRatings>(_onGetDoctorRatings);
    on<GetDoctorAverageRating>(_onGetDoctorAverageRating);
  }

  Future<void> _onSubmitDoctorRating(
    SubmitDoctorRating event,
    Emitter<RatingState> emit,
  ) async {
    emit(RatingLoading());
    final result = await submitDoctorRatingUseCase(event.rating);
    emit(_mapFailureOrSuccessToState(result, (_) => RatingSubmitted()));
  }

  Future<void> _onCheckPatientRatedAppointment(
    CheckPatientRatedAppointment event,
    Emitter<RatingState> emit,
  ) async {
    emit(RatingLoading());
    final result = await hasPatientRatedAppointmentUseCase(
      event.patientId,
      event.rendezVousId,
    );
    emit(
      _mapFailureOrHasRatedToState(
        result,
        (hasRated) => PatientRatingChecked(hasRated: hasRated),
      ),
    );
  }

  Future<void> _onGetDoctorRatings(
    GetDoctorRatings event,
    Emitter<RatingState> emit,
  ) async {
    if (state is! DoctorRatingsLoaded && state is! DoctorRatingState) {
      emit(RatingLoading());
    }

    final result = await getDoctorRatingsUseCase(event.doctorId);

    result.fold((failure) => emit(RatingError(_mapFailureToMessage(failure))), (
      ratings,
    ) {
      if (state is DoctorRatingState) {
        final currentState = state as DoctorRatingState;
        emit(
          DoctorRatingState(
            averageRating: currentState.averageRating,
            ratings: ratings,
          ),
        );
      } else {
        emit(DoctorRatingState(averageRating: 0.0, ratings: ratings));
      }
    });
  }

  Future<void> _onGetDoctorAverageRating(
    GetDoctorAverageRating event,
    Emitter<RatingState> emit,
  ) async {
    if (state is! DoctorAverageRatingLoaded && state is! DoctorRatingState) {
      emit(RatingLoading());
    }

    final result = await getDoctorAverageRatingUseCase(event.doctorId);

    result.fold((failure) => emit(RatingError(_mapFailureToMessage(failure))), (
      averageRating,
    ) {
      if (state is DoctorRatingState) {
        final currentState = state as DoctorRatingState;
        emit(
          DoctorRatingState(
            averageRating: averageRating,
            ratings: currentState.ratings,
          ),
        );
      } else {
        emit(
          DoctorRatingState(averageRating: averageRating, ratings: const []),
        );
      }
    });
  }

  RatingState _mapFailureOrSuccessToState(
    Either<Failure, Unit> failureOrSuccess,
    RatingState Function(Unit) onSuccess,
  ) {
    return failureOrSuccess.fold(
      (failure) => RatingError(_mapFailureToMessage(failure)),
      onSuccess,
    );
  }

  RatingState _mapFailureOrHasRatedToState(
    Either<Failure, bool> failureOrHasRated,
    RatingState Function(bool) onSuccess,
  ) {
    return failureOrHasRated.fold(
      (failure) => RatingError(_mapFailureToMessage(failure)),
      onSuccess,
    );
  }

  RatingState _mapFailureOrRatingsToState(
    Either<Failure, List<DoctorRatingEntity>> failureOrRatings,
    RatingState Function(List<DoctorRatingEntity>) onSuccess,
  ) {
    return failureOrRatings.fold(
      (failure) => RatingError(_mapFailureToMessage(failure)),
      onSuccess,
    );
  }

  RatingState _mapFailureOrAverageRatingToState(
    Either<Failure, double> failureOrAverageRating,
    RatingState Function(double) onSuccess,
  ) {
    return failureOrAverageRating.fold(
      (failure) => RatingError(_mapFailureToMessage(failure)),
      onSuccess,
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Une erreur serveur s\'est produite';
      case ServerMessageFailure:
        return (failure as ServerMessageFailure).message;
      case OfflineFailure:
        return 'Pas de connexion internet';
      default:
        return 'Une erreur inattendue s\'est produite';
    }
  }
}
