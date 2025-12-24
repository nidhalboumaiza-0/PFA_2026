part of 'rating_bloc.dart';

abstract class RatingState extends Equatable {
  const RatingState();
  
  @override
  List<Object?> get props => [];
}

class RatingInitial extends RatingState {}

class RatingLoading extends RatingState {}

class RatingSubmitted extends RatingState {}

class PatientRatingChecked extends RatingState {
  final bool hasRated;

  const PatientRatingChecked({required this.hasRated});

  @override
  List<Object> get props => [hasRated];
}

class DoctorRatingsLoaded extends RatingState {
  final List<DoctorRatingEntity> ratings;

  const DoctorRatingsLoaded({required this.ratings});

  @override
  List<Object> get props => [ratings];
}

class DoctorAverageRatingLoaded extends RatingState {
  final double averageRating;

  const DoctorAverageRatingLoaded({required this.averageRating});

  @override
  List<Object> get props => [averageRating];
}

// Combined state that holds both ratings and average rating
class DoctorRatingState extends RatingState {
  final double averageRating;
  final List<DoctorRatingEntity> ratings;

  const DoctorRatingState({
    required this.averageRating,
    required this.ratings,
  });

  @override
  List<Object> get props => [averageRating, ratings];
}

class RatingError extends RatingState {
  final String message;

  const RatingError(this.message);

  @override
  List<Object> get props => [message];
} 