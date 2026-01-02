import 'package:equatable/equatable.dart';

/// Entity representing a doctor review from a patient
class DoctorReviewEntity extends Equatable {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String? patientPhoto;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final String? appointmentId;
  final bool isVerified; // Verified review from actual appointment

  const DoctorReviewEntity({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    this.patientPhoto,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.appointmentId,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
        id,
        doctorId,
        patientId,
        patientName,
        patientPhoto,
        rating,
        comment,
        createdAt,
        appointmentId,
        isVerified,
      ];
}

/// Statistics summary for doctor ratings
class DoctorRatingStats extends Equatable {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  const DoctorRatingStats({
    required this.averageRating,
    required this.totalReviews,
    this.fiveStarCount = 0,
    this.fourStarCount = 0,
    this.threeStarCount = 0,
    this.twoStarCount = 0,
    this.oneStarCount = 0,
  });

  /// Calculate percentage for each star rating
  double getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    switch (stars) {
      case 5:
        return fiveStarCount / totalReviews;
      case 4:
        return fourStarCount / totalReviews;
      case 3:
        return threeStarCount / totalReviews;
      case 2:
        return twoStarCount / totalReviews;
      case 1:
        return oneStarCount / totalReviews;
      default:
        return 0;
    }
  }

  @override
  List<Object?> get props => [
        averageRating,
        totalReviews,
        fiveStarCount,
        fourStarCount,
        threeStarCount,
        twoStarCount,
        oneStarCount,
      ];
}
