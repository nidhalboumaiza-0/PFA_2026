import '../../domain/entities/doctor_review_entity.dart';

/// Model class for doctor reviews with JSON serialization
class ReviewModel extends DoctorReviewEntity {
  const ReviewModel({
    required super.id,
    required super.doctorId,
    required super.patientId,
    required super.patientName,
    super.patientPhoto,
    required super.rating,
    super.comment,
    required super.createdAt,
    super.appointmentId,
    super.isVerified,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Handle nested patient object if present
    final patient = json['patient'] as Map<String, dynamic>?;
    
    return ReviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      patientId: json['patientId'] ?? patient?['_id'] ?? '',
      patientName: patient?['fullName'] ?? 
                   json['patientName'] ?? 
                   '${patient?['firstName'] ?? ''} ${patient?['lastName'] ?? ''}'.trim(),
      patientPhoto: patient?['photo'] ?? json['patientPhoto'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      appointmentId: json['appointmentId'],
      isVerified: json['isVerified'] ?? true, // Reviews from API are verified
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhoto': patientPhoto,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'appointmentId': appointmentId,
      'isVerified': isVerified,
    };
  }

  factory ReviewModel.fromEntity(DoctorReviewEntity entity) {
    return ReviewModel(
      id: entity.id,
      doctorId: entity.doctorId,
      patientId: entity.patientId,
      patientName: entity.patientName,
      patientPhoto: entity.patientPhoto,
      rating: entity.rating,
      comment: entity.comment,
      createdAt: entity.createdAt,
      appointmentId: entity.appointmentId,
      isVerified: entity.isVerified,
    );
  }
}

/// Model for rating statistics with JSON serialization
class RatingStatsModel extends DoctorRatingStats {
  const RatingStatsModel({
    required super.averageRating,
    required super.totalReviews,
    super.fiveStarCount,
    super.fourStarCount,
    super.threeStarCount,
    super.twoStarCount,
    super.oneStarCount,
  });

  factory RatingStatsModel.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    
    return RatingStatsModel(
      averageRating: (json['averageRating'] ?? json['rating'] ?? 0.0 as num).toDouble(),
      totalReviews: json['totalReviews'] ?? json['total'] ?? 0,
      fiveStarCount: breakdown['5'] ?? json['fiveStarCount'] ?? 0,
      fourStarCount: breakdown['4'] ?? json['fourStarCount'] ?? 0,
      threeStarCount: breakdown['3'] ?? json['threeStarCount'] ?? 0,
      twoStarCount: breakdown['2'] ?? json['twoStarCount'] ?? 0,
      oneStarCount: breakdown['1'] ?? json['oneStarCount'] ?? 0,
    );
  }

  /// Create stats from a list of reviews
  factory RatingStatsModel.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const RatingStatsModel(
        averageRating: 0,
        totalReviews: 0,
      );
    }

    int fiveStar = 0, fourStar = 0, threeStar = 0, twoStar = 0, oneStar = 0;
    double sum = 0;

    for (final review in reviews) {
      sum += review.rating;
      switch (review.rating.round()) {
        case 5:
          fiveStar++;
          break;
        case 4:
          fourStar++;
          break;
        case 3:
          threeStar++;
          break;
        case 2:
          twoStar++;
          break;
        case 1:
          oneStar++;
          break;
      }
    }

    return RatingStatsModel(
      averageRating: sum / reviews.length,
      totalReviews: reviews.length,
      fiveStarCount: fiveStar,
      fourStarCount: fourStar,
      threeStarCount: threeStar,
      twoStarCount: twoStar,
      oneStarCount: oneStar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'breakdown': {
        '5': fiveStarCount,
        '4': fourStarCount,
        '3': threeStarCount,
        '2': twoStarCount,
        '1': oneStarCount,
      },
    };
  }
}
