import 'package:medical_app/features/ratings/domain/entities/doctor_rating_entity.dart';

class DoctorRatingModel extends DoctorRatingEntity {
  DoctorRatingModel({
    String? id,
    required String doctorId,
    required String patientId,
    String? patientName,
    required double rating,
    String? comment,
    required DateTime createdAt,
    required String rendezVousId,
  }) : super(
    id: id,
    doctorId: doctorId,
    patientId: patientId,
    patientName: patientName,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
    rendezVousId: rendezVousId,
  );

  factory DoctorRatingModel.fromJson(Map<String, dynamic> json) {
    return DoctorRatingModel(
      id: json['id'] as String?,
      doctorId: json['doctorId'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rendezVousId: json['rendezVousId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'rating': rating,
      if (comment != null) 'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'rendezVousId': rendezVousId,
    };
  }
} 