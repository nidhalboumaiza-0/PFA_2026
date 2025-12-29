import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/appointment_model.dart';
import '../models/time_slot_model.dart';

/// Abstract interface for local appointment data source
abstract class AppointmentLocalDataSource {
  /// Cache a list of appointments locally
  Future<void> cacheAppointments(List<AppointmentModel> appointments, {String? cacheKey});

  /// Get last cached appointments
  Future<List<AppointmentModel>> getLastAppointments({String? cacheKey});

  /// Cache doctor availability locally
  Future<void> cacheDoctorAvailability(String doctorId, List<TimeSlotModel> availability);

  /// Get cached doctor availability
  Future<List<TimeSlotModel>> getDoctorAvailability(String doctorId);

  /// Cache patient appointments
  Future<void> cachePatientAppointments(List<AppointmentModel> appointments, {String? status});

  /// Get cached patient appointments
  Future<List<AppointmentModel>> getCachedPatientAppointments({String? status});

  /// Cache doctor appointments
  Future<void> cacheDoctorAppointments(List<AppointmentModel> appointments, {String? status, DateTime? date});

  /// Get cached doctor appointments
  Future<List<AppointmentModel>> getCachedDoctorAppointments({String? status, DateTime? date});

  /// Cache appointment requests (for doctors)
  Future<void> cacheAppointmentRequests(List<AppointmentModel> requests);

  /// Get cached appointment requests
  Future<List<AppointmentModel>> getCachedAppointmentRequests();

  /// Clear all cached appointment data
  Future<void> clearCache();

  /// Check if cache has valid data
  Future<bool> hasCachedData({String? cacheKey});
}

/// Implementation of AppointmentLocalDataSource using Hive
class AppointmentLocalDataSourceImpl implements AppointmentLocalDataSource {
  static const String _appointmentsBoxName = 'appointments_cache';
  static const String _availabilityBoxName = 'availability_cache';
  static const String _cacheMetaBoxName = 'cache_meta';
  
  // Cache expiration time (30 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 30);

  Box<String>? _appointmentsBox;
  Box<String>? _availabilityBox;
  Box<String>? _cacheMetaBox;

  void _log(String method, String message) {
    print('[AppointmentLocalDataSource.$method] $message');
  }

  /// Initialize the Hive boxes
  Future<void> init() async {
    _log('init', 'Initializing appointment cache boxes...');
    
    if (!Hive.isBoxOpen(_appointmentsBoxName)) {
      _appointmentsBox = await Hive.openBox<String>(_appointmentsBoxName);
    } else {
      _appointmentsBox = Hive.box<String>(_appointmentsBoxName);
    }
    
    if (!Hive.isBoxOpen(_availabilityBoxName)) {
      _availabilityBox = await Hive.openBox<String>(_availabilityBoxName);
    } else {
      _availabilityBox = Hive.box<String>(_availabilityBoxName);
    }
    
    if (!Hive.isBoxOpen(_cacheMetaBoxName)) {
      _cacheMetaBox = await Hive.openBox<String>(_cacheMetaBoxName);
    } else {
      _cacheMetaBox = Hive.box<String>(_cacheMetaBoxName);
    }
    
    _log('init', 'Appointment cache boxes initialized');
  }

  Future<Box<String>> get _appointmentsBoxReady async {
    if (_appointmentsBox == null || !_appointmentsBox!.isOpen) {
      await init();
    }
    return _appointmentsBox!;
  }

  Future<Box<String>> get _availabilityBoxReady async {
    if (_availabilityBox == null || !_availabilityBox!.isOpen) {
      await init();
    }
    return _availabilityBox!;
  }

  Future<Box<String>> get _cacheMetaBoxReady async {
    if (_cacheMetaBox == null || !_cacheMetaBox!.isOpen) {
      await init();
    }
    return _cacheMetaBox!;
  }

  /// Generate cache key with timestamp
  String _generateCacheKey(String baseKey) {
    return '${baseKey}_data';
  }

  String _generateMetaKey(String baseKey) {
    return '${baseKey}_meta';
  }

  /// Save cache metadata (timestamp)
  Future<void> _saveCacheMeta(String key) async {
    final box = await _cacheMetaBoxReady;
    final meta = {
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put(_generateMetaKey(key), jsonEncode(meta));
  }

  /// Check if cache is valid (not expired)
  Future<bool> _isCacheValid(String key) async {
    final box = await _cacheMetaBoxReady;
    final metaJson = box.get(_generateMetaKey(key));
    
    if (metaJson == null) return false;
    
    try {
      final meta = jsonDecode(metaJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(meta['timestamp'] as String);
      final isValid = DateTime.now().difference(timestamp) < _cacheExpiration;
      _log('_isCacheValid', 'Cache for $key is ${isValid ? "valid" : "expired"}');
      return isValid;
    } catch (e) {
      _log('_isCacheValid', 'Error checking cache validity: $e');
      return false;
    }
  }

  /// Convert appointments to JSON string for storage
  String _appointmentsToJson(List<AppointmentModel> appointments) {
    final list = appointments.map((a) => a.toJson()).toList();
    return jsonEncode(list);
  }

  /// Parse appointments from JSON string
  List<AppointmentModel> _appointmentsFromJson(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('_appointmentsFromJson', 'Error parsing appointments: $e');
      return [];
    }
  }

  /// Convert time slots to JSON string for storage
  String _timeSlotsToJson(List<TimeSlotModel> slots) {
    final list = slots.map((s) => s.toJson()).toList();
    return jsonEncode(list);
  }

  /// Parse time slots from JSON string
  List<TimeSlotModel> _timeSlotsFromJson(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((json) => TimeSlotModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('_timeSlotsFromJson', 'Error parsing time slots: $e');
      return [];
    }
  }

  // ============== Generic Appointment Caching ==============

  @override
  Future<void> cacheAppointments(
    List<AppointmentModel> appointments, {
    String? cacheKey,
  }) async {
    final key = cacheKey ?? 'default_appointments';
    _log('cacheAppointments', 'Caching ${appointments.length} appointments with key: $key');
    
    final box = await _appointmentsBoxReady;
    await box.put(_generateCacheKey(key), _appointmentsToJson(appointments));
    await _saveCacheMeta(key);
  }

  @override
  Future<List<AppointmentModel>> getLastAppointments({String? cacheKey}) async {
    final key = cacheKey ?? 'default_appointments';
    _log('getLastAppointments', 'Getting cached appointments with key: $key');
    
    final box = await _appointmentsBoxReady;
    final jsonString = box.get(_generateCacheKey(key));
    
    if (jsonString == null) {
      _log('getLastAppointments', 'No cached data found');
      return [];
    }
    
    final appointments = _appointmentsFromJson(jsonString);
    _log('getLastAppointments', 'Retrieved ${appointments.length} cached appointments');
    return appointments;
  }

  // ============== Doctor Availability Caching ==============

  @override
  Future<void> cacheDoctorAvailability(
    String doctorId,
    List<TimeSlotModel> availability,
  ) async {
    _log('cacheDoctorAvailability', 'Caching ${availability.length} slots for doctor: $doctorId');
    
    final box = await _availabilityBoxReady;
    final key = 'doctor_availability_$doctorId';
    await box.put(_generateCacheKey(key), _timeSlotsToJson(availability));
    await _saveCacheMeta(key);
  }

  @override
  Future<List<TimeSlotModel>> getDoctorAvailability(String doctorId) async {
    _log('getDoctorAvailability', 'Getting cached availability for doctor: $doctorId');
    
    final box = await _availabilityBoxReady;
    final key = 'doctor_availability_$doctorId';
    final jsonString = box.get(_generateCacheKey(key));
    
    if (jsonString == null) {
      _log('getDoctorAvailability', 'No cached data found');
      return [];
    }
    
    final slots = _timeSlotsFromJson(jsonString);
    _log('getDoctorAvailability', 'Retrieved ${slots.length} cached slots');
    return slots;
  }

  // ============== Patient Appointments Caching ==============

  @override
  Future<void> cachePatientAppointments(
    List<AppointmentModel> appointments, {
    String? status,
  }) async {
    final key = 'patient_appointments${status != null ? '_$status' : ''}';
    _log('cachePatientAppointments', 'Caching ${appointments.length} patient appointments (status: $status)');
    await cacheAppointments(appointments, cacheKey: key);
  }

  @override
  Future<List<AppointmentModel>> getCachedPatientAppointments({String? status}) async {
    final key = 'patient_appointments${status != null ? '_$status' : ''}';
    _log('getCachedPatientAppointments', 'Getting cached patient appointments (status: $status)');
    return getLastAppointments(cacheKey: key);
  }

  // ============== Doctor Appointments Caching ==============

  @override
  Future<void> cacheDoctorAppointments(
    List<AppointmentModel> appointments, {
    String? status,
    DateTime? date,
  }) async {
    final datePart = date != null ? '_${date.toIso8601String().split('T')[0]}' : '';
    final key = 'doctor_appointments${status != null ? '_$status' : ''}$datePart';
    _log('cacheDoctorAppointments', 'Caching ${appointments.length} doctor appointments (status: $status, date: $date)');
    await cacheAppointments(appointments, cacheKey: key);
  }

  @override
  Future<List<AppointmentModel>> getCachedDoctorAppointments({
    String? status,
    DateTime? date,
  }) async {
    final datePart = date != null ? '_${date.toIso8601String().split('T')[0]}' : '';
    final key = 'doctor_appointments${status != null ? '_$status' : ''}$datePart';
    _log('getCachedDoctorAppointments', 'Getting cached doctor appointments (status: $status, date: $date)');
    return getLastAppointments(cacheKey: key);
  }

  // ============== Appointment Requests Caching ==============

  @override
  Future<void> cacheAppointmentRequests(List<AppointmentModel> requests) async {
    const key = 'appointment_requests';
    _log('cacheAppointmentRequests', 'Caching ${requests.length} appointment requests');
    await cacheAppointments(requests, cacheKey: key);
  }

  @override
  Future<List<AppointmentModel>> getCachedAppointmentRequests() async {
    const key = 'appointment_requests';
    _log('getCachedAppointmentRequests', 'Getting cached appointment requests');
    return getLastAppointments(cacheKey: key);
  }

  // ============== Cache Management ==============

  @override
  Future<void> clearCache() async {
    _log('clearCache', 'Clearing all appointment cache...');
    
    final appointmentsBox = await _appointmentsBoxReady;
    final availabilityBox = await _availabilityBoxReady;
    final metaBox = await _cacheMetaBoxReady;
    
    await appointmentsBox.clear();
    await availabilityBox.clear();
    await metaBox.clear();
    
    _log('clearCache', 'Cache cleared');
  }

  @override
  Future<bool> hasCachedData({String? cacheKey}) async {
    final key = cacheKey ?? 'default_appointments';
    final box = await _appointmentsBoxReady;
    final hasData = box.containsKey(_generateCacheKey(key));
    
    if (!hasData) return false;
    
    // Also check if cache is still valid
    return _isCacheValid(key);
  }
}
