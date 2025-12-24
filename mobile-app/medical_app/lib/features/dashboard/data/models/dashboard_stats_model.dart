import 'package:medical_app/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import '../../../rendez_vous/data/models/RendezVous.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    required int totalPatients,
    required int totalAppointments,
    required int pendingAppointments,
    required int completedAppointments,
    required int cancelledAppointments,
    required List<AppointmentEntity> upcomingAppointments,
  }) : super(
         totalPatients: totalPatients,
         totalAppointments: totalAppointments,
         pendingAppointments: pendingAppointments,
         completedAppointments: completedAppointments,
         cancelledAppointments: cancelledAppointments,
         upcomingAppointments: upcomingAppointments,
       );

  // MongoDB JSON deserializer
  factory DashboardStatsModel.fromJson(
    Map<String, dynamic> json, {
    required List<RendezVousModel> upcomingAppointments,
  }) {
    // Convert RendezVousModel to AppointmentEntity
    List<AppointmentEntity> appointmentEntities =
        upcomingAppointments
            .map(
              (rdv) => AppointmentEntity(
                id: rdv.id ?? '',
                patientId: rdv.patient,
                patientName:
                    '${rdv.patientName ?? ''} ${rdv.patientLastName ?? ''}',
                appointmentDate: rdv.startDate,
                status: rdv.status,
                appointmentType: rdv.serviceName,
              ),
            )
            .toList();

    return DashboardStatsModel(
      totalPatients: json['totalPatients'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      pendingAppointments: json['pendingAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      cancelledAppointments: json['cancelledAppointments'] ?? 0,
      upcomingAppointments: appointmentEntities,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'totalPatients': totalPatients,
      'totalAppointments': totalAppointments,
      'pendingAppointments': pendingAppointments,
      'completedAppointments': completedAppointments,
      'cancelledAppointments': cancelledAppointments,
    };
  }
}
