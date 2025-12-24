import 'package:equatable/equatable.dart';

class DoctorRatingEntity extends Equatable {
  final String? id;
  final String doctorId;
  final String patientId;
  final String? patientName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final String rendezVousId;

  const DoctorRatingEntity({
    this.id,
    required this.doctorId,
    required this.patientId,
    this.patientName,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.rendezVousId,
  });

  factory DoctorRatingEntity.create({
    String? id,
    required String doctorId,
    required String patientId,
    String? patientName,
    required double rating,
    String? comment,
    DateTime? createdAt,
    required String rendezVousId,
  }) {
    return DoctorRatingEntity(
      id: id,
      doctorId: doctorId,
      patientId: patientId,
      patientName: patientName,
      rating: rating,
      comment: comment,
      createdAt: createdAt ?? DateTime.now(),
      rendezVousId: rendezVousId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    doctorId,
    patientId,
    patientName,
    rating,
    comment,
    createdAt,
    rendezVousId,
  ];
} 