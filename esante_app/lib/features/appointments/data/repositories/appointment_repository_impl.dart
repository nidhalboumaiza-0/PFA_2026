import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/time_slot_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../presentation/bloc/doctor/doctor_appointment_bloc.dart';
import '../datasources/appointment_remote_datasource.dart';
import '../datasources/appointment_local_datasource.dart';
import '../models/appointment_model.dart';
import '../models/time_slot_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;
  final AppointmentLocalDataSource localDataSource;

  AppointmentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  void _log(String method, String message) {
    print('[AppointmentRepositoryImpl.$method] $message');
  }

  /// Check if error is a network-related error
  bool _isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is NetworkException) return true;
    if (error.toString().contains('SocketException')) return true;
    if (error.toString().contains('Connection refused')) return true;
    if (error.toString().contains('Network is unreachable')) return true;
    if (error.toString().contains('No internet')) return true;
    return false;
  }

  // ============== Patient Operations ==============

  @override
  Future<Either<Failure, List<TimeSlotEntity>>> viewDoctorAvailability({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _log('viewDoctorAvailability', 'Fetching availability for doctor: $doctorId from remote');
      final slots = await remoteDataSource.viewDoctorAvailability(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Cache the result
      await localDataSource.cacheDoctorAvailability(doctorId, slots);
      _log('viewDoctorAvailability', 'Cached ${slots.length} availability slots');
      
      return Right(slots);
    } catch (e) {
      _log('viewDoctorAvailability', 'Remote fetch failed: $e');
      
      // Try to get from local cache on network error
      if (_isNetworkError(e)) {
        _log('viewDoctorAvailability', 'Network error, trying local cache');
        try {
          final cachedSlots = await localDataSource.getDoctorAvailability(doctorId);
          if (cachedSlots.isNotEmpty) {
            _log('viewDoctorAvailability', 'Returning ${cachedSlots.length} cached slots (offline mode)');
            return Right(cachedSlots);
          }
        } catch (cacheError) {
          _log('viewDoctorAvailability', 'Local cache error: $cacheError');
        }
        return const Left(NetworkFailure());
      }
      
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> requestAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? reason,
    String? notes,
  }) async {
    try {
      final appointment = await remoteDataSource.requestAppointment(
        doctorId: doctorId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        reason: reason,
        notes: notes,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> cancelAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    try {
      final appointment = await remoteDataSource.cancelAppointment(
        appointmentId: appointmentId,
        reason: reason,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> requestReschedule({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    try {
      final appointment = await remoteDataSource.requestReschedule(
        appointmentId: appointmentId,
        newDate: newDate,
        newTime: newTime,
        reason: reason,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getPatientAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _log('getPatientAppointments', 'Fetching patient appointments from remote (status: $status)');
      final appointments = await remoteDataSource.getPatientAppointments(
        status: status,
        page: page,
        limit: limit,
      );
      
      // Cache the result
      await localDataSource.cachePatientAppointments(
        appointments.cast<AppointmentModel>(),
        status: status,
      );
      _log('getPatientAppointments', 'Cached ${appointments.length} patient appointments');
      
      return Right(appointments);
    } catch (e) {
      _log('getPatientAppointments', 'Remote fetch failed: $e');
      
      // Try to get from local cache on network error
      if (_isNetworkError(e)) {
        _log('getPatientAppointments', 'Network error, trying local cache');
        try {
          final cachedAppointments = await localDataSource.getCachedPatientAppointments(status: status);
          if (cachedAppointments.isNotEmpty) {
            _log('getPatientAppointments', 'Returning ${cachedAppointments.length} cached appointments (offline mode)');
            return Right(cachedAppointments);
          }
        } catch (cacheError) {
          _log('getPatientAppointments', 'Local cache error: $cacheError');
        }
        return const Left(NetworkFailure());
      }
      
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  // ============== Doctor Operations ==============

  @override
  Future<Either<Failure, TimeSlotEntity>> setAvailability({
    required DateTime date,
    required List<String> timeSlots,
    String? specialNotes,
  }) async {
    try {
      final slot = await remoteDataSource.setAvailability(
        date: date,
        timeSlots: timeSlots,
        specialNotes: specialNotes,
      );
      return Right(slot);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> bulkSetAvailability({
    required List<AvailabilityEntry> availabilities,
    bool skipExisting = true,
  }) async {
    try {
      final result = await remoteDataSource.bulkSetAvailability(
        availabilities: availabilities,
        skipExisting: skipExisting,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimeSlotEntity>>> getDoctorAvailability({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _log('getDoctorAvailability', 'Fetching doctor availability from remote');
      final slots = await remoteDataSource.getDoctorAvailability(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Cache with a special key for doctor's own availability
      await localDataSource.cacheDoctorAvailability('self', slots.cast<TimeSlotModel>());
      _log('getDoctorAvailability', 'Cached ${slots.length} availability slots');
      
      return Right(slots);
    } catch (e) {
      _log('getDoctorAvailability', 'Remote fetch failed: $e');
      
      if (_isNetworkError(e)) {
        _log('getDoctorAvailability', 'Network error, trying local cache');
        try {
          final cachedSlots = await localDataSource.getDoctorAvailability('self');
          if (cachedSlots.isNotEmpty) {
            _log('getDoctorAvailability', 'Returning ${cachedSlots.length} cached slots (offline mode)');
            return Right(cachedSlots);
          }
        } catch (cacheError) {
          _log('getDoctorAvailability', 'Local cache error: $cacheError');
        }
        return const Left(NetworkFailure());
      }
      
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointmentRequests({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _log('getAppointmentRequests', 'Fetching appointment requests from remote');
      final requests = await remoteDataSource.getAppointmentRequests(
        page: page,
        limit: limit,
      );
      
      // Cache the requests
      await localDataSource.cacheAppointmentRequests(requests.cast<AppointmentModel>());
      _log('getAppointmentRequests', 'Cached ${requests.length} appointment requests');
      
      return Right(requests);
    } catch (e) {
      _log('getAppointmentRequests', 'Remote fetch failed: $e');
      
      if (_isNetworkError(e)) {
        _log('getAppointmentRequests', 'Network error, trying local cache');
        try {
          final cachedRequests = await localDataSource.getCachedAppointmentRequests();
          if (cachedRequests.isNotEmpty) {
            _log('getAppointmentRequests', 'Returning ${cachedRequests.length} cached requests (offline mode)');
            return Right(cachedRequests);
          }
        } catch (cacheError) {
          _log('getAppointmentRequests', 'Local cache error: $cacheError');
        }
        return const Left(NetworkFailure());
      }
      
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> confirmAppointment({
    required String appointmentId,
  }) async {
    try {
      final appointment = await remoteDataSource.confirmAppointment(
        appointmentId: appointmentId,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> rejectAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    try {
      final appointment = await remoteDataSource.rejectAppointment(
        appointmentId: appointmentId,
        reason: reason,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    try {
      final appointment = await remoteDataSource.rescheduleAppointment(
        appointmentId: appointmentId,
        newDate: newDate,
        newTime: newTime,
        reason: reason,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> approveReschedule({
    required String appointmentId,
  }) async {
    try {
      final appointment = await remoteDataSource.approveReschedule(
        appointmentId: appointmentId,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> rejectReschedule({
    required String appointmentId,
    String? reason,
  }) async {
    try {
      final appointment = await remoteDataSource.rejectReschedule(
        appointmentId: appointmentId,
        reason: reason,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> completeAppointment({
    required String appointmentId,
    String? notes,
  }) async {
    try {
      final appointment = await remoteDataSource.completeAppointment(
        appointmentId: appointmentId,
        notes: notes,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getDoctorAppointments({
    String? status,
    DateTime? date,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _log('getDoctorAppointments', 'Fetching doctor appointments from remote (status: $status, date: $date)');
      final appointments = await remoteDataSource.getDoctorAppointments(
        status: status,
        date: date,
        page: page,
        limit: limit,
      );
      
      // Cache the result
      await localDataSource.cacheDoctorAppointments(
        appointments.cast<AppointmentModel>(),
        status: status,
        date: date,
      );
      _log('getDoctorAppointments', 'Cached ${appointments.length} doctor appointments');
      
      return Right(appointments);
    } catch (e) {
      _log('getDoctorAppointments', 'Remote fetch failed: $e');
      
      if (_isNetworkError(e)) {
        _log('getDoctorAppointments', 'Network error, trying local cache');
        try {
          final cachedAppointments = await localDataSource.getCachedDoctorAppointments(
            status: status,
            date: date,
          );
          if (cachedAppointments.isNotEmpty) {
            _log('getDoctorAppointments', 'Returning ${cachedAppointments.length} cached appointments (offline mode)');
            return Right(cachedAppointments);
          }
        } catch (cacheError) {
          _log('getDoctorAppointments', 'Local cache error: $cacheError');
        }
        return const Left(NetworkFailure());
      }
      
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppointmentStatistics>> getAppointmentStatistics() async {
    try {
      final stats = await remoteDataSource.getAppointmentStatistics();
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  // ============== Shared Operations ==============

  @override
  Future<Either<Failure, AppointmentEntity>> getAppointmentDetails({
    required String appointmentId,
  }) async {
    try {
      final appointment = await remoteDataSource.getAppointmentDetails(
        appointmentId: appointmentId,
      );
      return Right(appointment);
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }
}
