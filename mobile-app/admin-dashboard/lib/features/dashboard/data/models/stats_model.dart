import '../../domain/entities/stats_entity.dart';

class StatsModel extends StatsEntity {
  const StatsModel({
    required int totalUsers,
    required int totalDoctors,
    required int totalPatients,
    required int totalAppointments,
    required int pendingAppointments,
    required int completedAppointments,
    required int cancelledAppointments,
    required Map<String, int> appointmentsPerDay,
    required Map<String, int> appointmentsPerMonth,
    required Map<String, int> appointmentsPerYear,
    List<DoctorStatistics> topDoctorsByCompletedAppointments = const [],
    List<DoctorStatistics> topDoctorsByCancelledAppointments = const [],
    List<PatientStatistics> topPatientsByCancelledAppointments = const [],
  }) : super(
         totalUsers: totalUsers,
         totalDoctors: totalDoctors,
         totalPatients: totalPatients,
         totalAppointments: totalAppointments,
         pendingAppointments: pendingAppointments,
         completedAppointments: completedAppointments,
         cancelledAppointments: cancelledAppointments,
         appointmentsPerDay: appointmentsPerDay,
         appointmentsPerMonth: appointmentsPerMonth,
         appointmentsPerYear: appointmentsPerYear,
         topDoctorsByCompletedAppointments: topDoctorsByCompletedAppointments,
         topDoctorsByCancelledAppointments: topDoctorsByCancelledAppointments,
         topPatientsByCancelledAppointments: topPatientsByCancelledAppointments,
       );

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      totalDoctors: json['totalDoctors'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      pendingAppointments: json['pendingAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      cancelledAppointments: json['cancelledAppointments'] ?? 0,
      appointmentsPerDay: _convertMapToStringIntMap(json['appointmentsPerDay']),
      appointmentsPerMonth: _convertMapToStringIntMap(
        json['appointmentsPerMonth'],
      ),
      appointmentsPerYear: _convertMapToStringIntMap(
        json['appointmentsPerYear'],
      ),
      topDoctorsByCompletedAppointments: _convertToDoctorStatsList(
        json['topDoctorsByCompletedAppointments'],
      ),
      topDoctorsByCancelledAppointments: _convertToDoctorStatsList(
        json['topDoctorsByCancelledAppointments'],
      ),
      topPatientsByCancelledAppointments: _convertToPatientStatsList(
        json['topPatientsByCancelledAppointments'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalDoctors': totalDoctors,
      'totalPatients': totalPatients,
      'totalAppointments': totalAppointments,
      'pendingAppointments': pendingAppointments,
      'completedAppointments': completedAppointments,
      'cancelledAppointments': cancelledAppointments,
      'appointmentsPerDay': appointmentsPerDay,
      'appointmentsPerMonth': appointmentsPerMonth,
      'appointmentsPerYear': appointmentsPerYear,
      'topDoctorsByCompletedAppointments':
          topDoctorsByCompletedAppointments
              .map((doctor) => _doctorStatsToJson(doctor))
              .toList(),
      'topDoctorsByCancelledAppointments':
          topDoctorsByCancelledAppointments
              .map((doctor) => _doctorStatsToJson(doctor))
              .toList(),
      'topPatientsByCancelledAppointments':
          topPatientsByCancelledAppointments
              .map((patient) => _patientStatsToJson(patient))
              .toList(),
    };
  }

  static Map<String, int> _convertMapToStringIntMap(dynamic map) {
    if (map == null) {
      return {};
    }

    Map<String, int> result = {};
    (map as Map<String, dynamic>).forEach((key, value) {
      if (value is int) {
        result[key] = value;
      } else if (value is double) {
        result[key] = value.toInt();
      } else if (value is String) {
        result[key] = int.tryParse(value) ?? 0;
      }
    });
    return result;
  }

  static List<DoctorStatistics> _convertToDoctorStatsList(dynamic list) {
    if (list == null) {
      return [];
    }

    return (list as List)
        .map(
          (item) => DoctorStatistics(
            id: item['id'] ?? '',
            name: item['name'] ?? '',
            email: item['email'] ?? '',
            appointmentCount: item['appointmentCount'] ?? 0,
            completionRate: (item['completionRate'] ?? 0.0).toDouble(),
          ),
        )
        .toList();
  }

  static List<PatientStatistics> _convertToPatientStatsList(dynamic list) {
    if (list == null) {
      return [];
    }

    return (list as List)
        .map(
          (item) => PatientStatistics(
            id: item['id'] ?? '',
            name: item['name'] ?? '',
            email: item['email'] ?? '',
            cancelledAppointments: item['cancelledAppointments'] ?? 0,
            totalAppointments: item['totalAppointments'] ?? 0,
            cancellationRate: (item['cancellationRate'] ?? 0.0).toDouble(),
          ),
        )
        .toList();
  }

  static Map<String, dynamic> _doctorStatsToJson(DoctorStatistics doctor) {
    return {
      'id': doctor.id,
      'name': doctor.name,
      'email': doctor.email,
      'appointmentCount': doctor.appointmentCount,
      'completionRate': doctor.completionRate,
    };
  }

  static Map<String, dynamic> _patientStatsToJson(PatientStatistics patient) {
    return {
      'id': patient.id,
      'name': patient.name,
      'email': patient.email,
      'cancelledAppointments': patient.cancelledAppointments,
      'totalAppointments': patient.totalAppointments,
      'cancellationRate': patient.cancellationRate,
    };
  }
}
