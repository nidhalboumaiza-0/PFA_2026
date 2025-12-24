import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/stats_entity.dart';
import '../models/stats_model.dart';

abstract class StatsRemoteDataSource {
  Future<StatsModel> getStats();
  Future<Map<String, int>> getAppointmentsPerDay();
  Future<Map<String, int>> getAppointmentsPerMonth();
  Future<Map<String, int>> getAppointmentsPerYear();
  Future<List<DoctorStatistics>> getTopDoctorsByCompletedAppointments();
  Future<List<DoctorStatistics>> getTopDoctorsByCancelledAppointments();
  Future<List<PatientStatistics>> getTopPatientsByCancelledAppointments();
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  final FirebaseFirestore firestore;

  StatsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<StatsModel> getStats() async {
    try {
      // Get user counts
      final userQuery = await firestore.collection('users').get();
      final users = userQuery.docs;

      final totalUsers = users.length;
      final totalDoctors =
          users.where((user) => user.data()['role'] == 'medecin').length;
      final totalPatients =
          users.where((user) => user.data()['role'] == 'patient').length;

      // Get appointment counts
      final appointmentQuery = await firestore.collection('appointments').get();
      final appointments = appointmentQuery.docs;

      final totalAppointments = appointments.length;
      final pendingAppointments =
          appointments
              .where((appointment) => appointment.data()['status'] == 'pending')
              .length;
      final completedAppointments =
          appointments
              .where(
                (appointment) => appointment.data()['status'] == 'completed',
              )
              .length;
      final cancelledAppointments =
          appointments
              .where(
                (appointment) => appointment.data()['status'] == 'cancelled',
              )
              .length;

      // Get time-based stats
      final appointmentsPerDay = await _getAppointmentsPerDayFromFirestore();
      final appointmentsPerMonth =
          await _getAppointmentsPerMonthFromFirestore();
      final appointmentsPerYear = await _getAppointmentsPerYearFromFirestore();

      // Get top doctors and patients stats
      final topDoctorsByCompletedAppointments =
          await getTopDoctorsByCompletedAppointments();
      final topDoctorsByCancelledAppointments =
          await getTopDoctorsByCancelledAppointments();
      final topPatientsByCancelledAppointments =
          await getTopPatientsByCancelledAppointments();

      return StatsModel(
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
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, int>> getAppointmentsPerDay() async {
    try {
      return await _getAppointmentsPerDayFromFirestore();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, int>> getAppointmentsPerMonth() async {
    try {
      return await _getAppointmentsPerMonthFromFirestore();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, int>> getAppointmentsPerYear() async {
    try {
      return await _getAppointmentsPerYearFromFirestore();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<DoctorStatistics>> getTopDoctorsByCompletedAppointments() async {
    try {
      // Get all doctors
      final doctorsQuery =
          await firestore
              .collection('users')
              .where('role', isEqualTo: 'medecin')
              .get();

      if (doctorsQuery.docs.isEmpty) {
        return [];
      }

      // For each doctor, count their appointments
      List<DoctorStatistics> doctorStats = [];

      for (var doctorDoc in doctorsQuery.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;

        // Count completed appointments for this doctor
        final appointmentsQuery =
            await firestore
                .collection('appointments')
                .where('doctorId', isEqualTo: doctorId)
                .where('status', isEqualTo: 'completed')
                .get();

        final totalAppointments =
            await firestore
                .collection('appointments')
                .where('doctorId', isEqualTo: doctorId)
                .get();

        final completedCount = appointmentsQuery.docs.length;
        final totalCount = totalAppointments.docs.length;
        final completionRate =
            totalCount > 0 ? completedCount / totalCount : 0.0;

        if (totalCount > 0) {
          doctorStats.add(
            DoctorStatistics(
              id: doctorId,
              name: doctorData['name'] ?? 'Unknown',
              email: doctorData['email'] ?? '',
              appointmentCount: completedCount,
              completionRate: completionRate,
            ),
          );
        }
      }

      // Sort by appointment count in descending order
      doctorStats.sort(
        (a, b) => b.appointmentCount.compareTo(a.appointmentCount),
      );

      // Return top 10 or less if there are fewer doctors
      return doctorStats.take(10).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<DoctorStatistics>> getTopDoctorsByCancelledAppointments() async {
    try {
      // Get all doctors
      final doctorsQuery =
          await firestore
              .collection('users')
              .where('role', isEqualTo: 'medecin')
              .get();

      if (doctorsQuery.docs.isEmpty) {
        return [];
      }

      // For each doctor, count their cancelled appointments
      List<DoctorStatistics> doctorStats = [];

      for (var doctorDoc in doctorsQuery.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;

        // Count cancelled appointments for this doctor
        final appointmentsQuery =
            await firestore
                .collection('appointments')
                .where('doctorId', isEqualTo: doctorId)
                .where('status', isEqualTo: 'cancelled')
                .get();

        final totalAppointments =
            await firestore
                .collection('appointments')
                .where('doctorId', isEqualTo: doctorId)
                .get();

        final cancelledCount = appointmentsQuery.docs.length;
        final totalCount = totalAppointments.docs.length;

        if (totalCount > 0) {
          doctorStats.add(
            DoctorStatistics(
              id: doctorId,
              name: doctorData['name'] ?? 'Unknown',
              email: doctorData['email'] ?? '',
              appointmentCount: cancelledCount,
              completionRate:
                  totalCount > 0 ? cancelledCount / totalCount : 0.0,
            ),
          );
        }
      }

      // Sort by cancelled appointment count in descending order
      doctorStats.sort(
        (a, b) => b.appointmentCount.compareTo(a.appointmentCount),
      );

      // Return top 10 or less if there are fewer doctors
      return doctorStats.take(10).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PatientStatistics>>
  getTopPatientsByCancelledAppointments() async {
    try {
      // Get all patients
      final patientsQuery =
          await firestore
              .collection('users')
              .where('role', isEqualTo: 'patient')
              .get();

      if (patientsQuery.docs.isEmpty) {
        return [];
      }

      // For each patient, count their cancelled appointments
      List<PatientStatistics> patientStats = [];

      for (var patientDoc in patientsQuery.docs) {
        final patientData = patientDoc.data();
        final patientId = patientDoc.id;

        // Count cancelled appointments for this patient
        final cancelledAppointmentsQuery =
            await firestore
                .collection('appointments')
                .where('patientId', isEqualTo: patientId)
                .where('status', isEqualTo: 'cancelled')
                .get();

        final totalAppointmentsQuery =
            await firestore
                .collection('appointments')
                .where('patientId', isEqualTo: patientId)
                .get();

        final cancelledCount = cancelledAppointmentsQuery.docs.length;
        final totalCount = totalAppointmentsQuery.docs.length;

        if (cancelledCount > 0) {
          patientStats.add(
            PatientStatistics(
              id: patientId,
              name: patientData['name'] ?? 'Unknown',
              email: patientData['email'] ?? '',
              cancelledAppointments: cancelledCount,
              totalAppointments: totalCount,
              cancellationRate:
                  totalCount > 0 ? cancelledCount / totalCount : 0.0,
            ),
          );
        }
      }

      // Sort by cancellation count in descending order
      patientStats.sort(
        (a, b) => b.cancelledAppointments.compareTo(a.cancelledAppointments),
      );

      // Return top 10 or less if there are fewer patients
      return patientStats.take(10).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, int>> _getAppointmentsPerDayFromFirestore() async {
    // Get appointments for the last 7 days
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    final appointmentQuery =
        await firestore
            .collection('appointments')
            .where(
              'date',
              isGreaterThanOrEqualTo: sevenDaysAgo.toIso8601String(),
            )
            .get();

    final appointments = appointmentQuery.docs;

    // Group by day
    Map<String, int> result = {};

    // Initialize with past 7 days
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      result[dayKey] = 0;
    }

    // Count appointments per day
    for (var appointment in appointments) {
      final appointmentData = appointment.data();
      final dateString = appointmentData['date'] as String;
      final date = DateTime.parse(dateString);
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      result[dayKey] = (result[dayKey] ?? 0) + 1;
    }

    return result;
  }

  Future<Map<String, int>> _getAppointmentsPerMonthFromFirestore() async {
    // Get appointments for the last 12 months
    final DateTime now = DateTime.now();
    final DateTime twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

    final appointmentQuery =
        await firestore
            .collection('appointments')
            .where(
              'date',
              isGreaterThanOrEqualTo: twelveMonthsAgo.toIso8601String(),
            )
            .get();

    final appointments = appointmentQuery.docs;

    // Group by month
    Map<String, int> result = {};

    // Initialize with past 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      result[monthKey] = 0;
    }

    // Count appointments per month
    for (var appointment in appointments) {
      final appointmentData = appointment.data();
      final dateString = appointmentData['date'] as String;
      final date = DateTime.parse(dateString);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      result[monthKey] = (result[monthKey] ?? 0) + 1;
    }

    return result;
  }

  Future<Map<String, int>> _getAppointmentsPerYearFromFirestore() async {
    // Get appointments for the last 5 years
    final DateTime now = DateTime.now();
    final DateTime fiveYearsAgo = DateTime(now.year - 5, 1, 1);

    final appointmentQuery =
        await firestore
            .collection('appointments')
            .where(
              'date',
              isGreaterThanOrEqualTo: fiveYearsAgo.toIso8601String(),
            )
            .get();

    final appointments = appointmentQuery.docs;

    // Group by year
    Map<String, int> result = {};

    // Initialize with past 5 years
    for (int i = 4; i >= 0; i--) {
      final year = now.year - i;
      result[year.toString()] = 0;
    }

    // Count appointments per year
    for (var appointment in appointments) {
      final appointmentData = appointment.data();
      final dateString = appointmentData['date'] as String;
      final date = DateTime.parse(dateString);
      final yearKey = date.year.toString();

      result[yearKey] = (result[yearKey] ?? 0) + 1;
    }

    return result;
  }
}
