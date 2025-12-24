part of 'rating_bloc.dart';

abstract class RatingEvent extends Equatable {
  const RatingEvent();

  @override
  List<Object> get props => [];
}

class SubmitDoctorRating extends RatingEvent {
  final DoctorRatingEntity rating;

  const SubmitDoctorRating(this.rating);

  @override
  List<Object> get props => [rating];
}

class CheckPatientRatedAppointment extends RatingEvent {
  final String patientId;
  final String rendezVousId;

  const CheckPatientRatedAppointment({
    required this.patientId,
    required this.rendezVousId,
  });

  @override
  List<Object> get props => [patientId, rendezVousId];
}

class GetDoctorRatings extends RatingEvent {
  final String doctorId;

  const GetDoctorRatings(this.doctorId);

  @override
  List<Object> get props => [doctorId];
}

class GetDoctorAverageRating extends RatingEvent {
  final String doctorId;

  const GetDoctorAverageRating(this.doctorId);

  @override
  List<Object> get props => [doctorId];
}
