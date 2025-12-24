import 'package:medical_app/features/referral/domain/entities/referral_entity.dart';

/// Model class for Referral with JSON serialization
class ReferralModel extends ReferralEntity {
  const ReferralModel({
    super.id,
    required super.referringDoctorId,
    required super.targetDoctorId,
    required super.patientId,
    super.referralDate,
    required super.reason,
    super.urgency,
    super.specialty,
    super.diagnosis,
    super.symptoms,
    super.relevantHistory,
    super.currentMedications,
    super.specificConcerns,
    super.attachedDocuments,
    super.status,
    super.statusHistory,
    super.includeFullHistory,
    super.appointmentDate,
    super.appointmentTime,
    super.appointmentId,
    super.preferredDates,
    super.referralNotes,
    super.responseNotes,
    super.completionNotes,
    super.createdAt,
    super.updatedAt,
    // Populated data
    super.referringDoctorName,
    super.referringDoctorSpecialty,
    super.targetDoctorName,
    super.targetDoctorSpecialty,
    super.patientName,
    super.patientPhone,
  });

  /// Status mapping from backend (English) to display (French)
  static const Map<String, String> _backendToDisplayStatus = {
    'pending': 'En attente',
    'accepted': 'Accepté',
    'rejected': 'Refusé',
    'in_progress': 'En cours',
    'completed': 'Terminé',
    'cancelled': 'Annulé',
  };

  /// Status mapping from display (French) to backend (English)
  static const Map<String, String> _displayToBackendStatus = {
    'En attente': 'pending',
    'Accepté': 'accepted',
    'Refusé': 'rejected',
    'En cours': 'in_progress',
    'Terminé': 'completed',
    'Annulé': 'cancelled',
  };

  /// Convert backend status to display status
  static String toDisplayStatus(String backendStatus) {
    return _backendToDisplayStatus[backendStatus.toLowerCase()] ?? backendStatus;
  }

  /// Convert display status to backend status
  static String toBackendStatus(String displayStatus) {
    return _displayToBackendStatus[displayStatus] ?? displayStatus.toLowerCase();
  }

  /// Create from JSON
  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    // Parse status history
    List<StatusHistoryEntry>? statusHistory;
    if (json['statusHistory'] != null) {
      statusHistory = (json['statusHistory'] as List)
          .map((e) => StatusHistoryEntry(
                status: toDisplayStatus(e['status'] ?? 'pending'),
                changedAt: DateTime.tryParse(e['changedAt'] ?? '') ?? DateTime.now(),
                changedBy: e['changedBy'],
                reason: e['reason'],
              ))
          .toList();
    }

    // Parse preferred dates
    List<DateTime>? preferredDates;
    if (json['preferredDates'] != null) {
      preferredDates = (json['preferredDates'] as List)
          .map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
          .toList();
    }

    // Extract populated referring doctor data
    String? referringDoctorName;
    String? referringDoctorSpecialty;
    if (json['referringDoctorId'] is Map) {
      final doctorData = json['referringDoctorId'] as Map<String, dynamic>;
      referringDoctorName = '${doctorData['nom'] ?? ''} ${doctorData['prenom'] ?? ''}'.trim();
      referringDoctorSpecialty = doctorData['specialite'];
    }

    // Extract populated target doctor data
    String? targetDoctorName;
    String? targetDoctorSpecialty;
    if (json['targetDoctorId'] is Map) {
      final doctorData = json['targetDoctorId'] as Map<String, dynamic>;
      targetDoctorName = '${doctorData['nom'] ?? ''} ${doctorData['prenom'] ?? ''}'.trim();
      targetDoctorSpecialty = doctorData['specialite'];
    }

    // Extract populated patient data
    String? patientName;
    String? patientPhone;
    if (json['patientId'] is Map) {
      final patientData = json['patientId'] as Map<String, dynamic>;
      patientName = '${patientData['nom'] ?? ''} ${patientData['prenom'] ?? ''}'.trim();
      patientPhone = patientData['telephone'];
    }

    // Get IDs (handle both string and populated object)
    String referringDoctorId = '';
    String targetDoctorId = '';
    String patientId = '';
    
    if (json['referringDoctorId'] is String) {
      referringDoctorId = json['referringDoctorId'];
    } else if (json['referringDoctorId'] is Map) {
      referringDoctorId = json['referringDoctorId']['_id'] ?? '';
    }
    
    if (json['targetDoctorId'] is String) {
      targetDoctorId = json['targetDoctorId'];
    } else if (json['targetDoctorId'] is Map) {
      targetDoctorId = json['targetDoctorId']['_id'] ?? '';
    }
    
    if (json['patientId'] is String) {
      patientId = json['patientId'];
    } else if (json['patientId'] is Map) {
      patientId = json['patientId']['_id'] ?? '';
    }

    return ReferralModel(
      id: json['_id'] ?? json['id'],
      referringDoctorId: referringDoctorId,
      targetDoctorId: targetDoctorId,
      patientId: patientId,
      referralDate: DateTime.tryParse(json['referralDate'] ?? ''),
      reason: json['reason'] ?? '',
      urgency: json['urgency'] ?? 'routine',
      specialty: json['specialty'],
      diagnosis: json['diagnosis'],
      symptoms: json['symptoms'] != null 
          ? List<String>.from(json['symptoms']) 
          : null,
      relevantHistory: json['relevantHistory'],
      currentMedications: json['currentMedications'],
      specificConcerns: json['specificConcerns'],
      attachedDocuments: json['attachedDocuments'] != null 
          ? List<String>.from(json['attachedDocuments']) 
          : null,
      status: toDisplayStatus(json['status'] ?? 'pending'),
      statusHistory: statusHistory,
      includeFullHistory: json['includeFullHistory'] ?? true,
      appointmentDate: DateTime.tryParse(json['appointmentDate'] ?? ''),
      appointmentTime: json['appointmentTime'],
      appointmentId: json['appointmentId'],
      preferredDates: preferredDates,
      referralNotes: json['referralNotes'],
      responseNotes: json['responseNotes'],
      completionNotes: json['completionNotes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      // Populated data
      referringDoctorName: referringDoctorName,
      referringDoctorSpecialty: referringDoctorSpecialty,
      targetDoctorName: targetDoctorName,
      targetDoctorSpecialty: targetDoctorSpecialty,
      patientName: patientName,
      patientPhone: patientPhone,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'referringDoctorId': referringDoctorId,
      'targetDoctorId': targetDoctorId,
      'patientId': patientId,
      if (referralDate != null) 'referralDate': referralDate!.toIso8601String(),
      'reason': reason,
      'urgency': urgency,
      if (specialty != null) 'specialty': specialty,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (symptoms != null) 'symptoms': symptoms,
      if (relevantHistory != null) 'relevantHistory': relevantHistory,
      if (currentMedications != null) 'currentMedications': currentMedications,
      if (specificConcerns != null) 'specificConcerns': specificConcerns,
      if (attachedDocuments != null) 'attachedDocuments': attachedDocuments,
      'status': toBackendStatus(status),
      'includeFullHistory': includeFullHistory,
      if (preferredDates != null) 
        'preferredDates': preferredDates!.map((d) => d.toIso8601String()).toList(),
      if (referralNotes != null) 'referralNotes': referralNotes,
      if (responseNotes != null) 'responseNotes': responseNotes,
      if (completionNotes != null) 'completionNotes': completionNotes,
    };
  }

  /// Create a request body for creating a new referral
  static Map<String, dynamic> createReferralRequest({
    required String targetDoctorId,
    required String patientId,
    required String reason,
    required String specialty,
    String urgency = 'routine',
    String? diagnosis,
    List<String>? symptoms,
    String? relevantHistory,
    String? currentMedications,
    String? specificConcerns,
    List<String>? attachedDocuments,
    bool includeFullHistory = true,
    List<DateTime>? preferredDates,
    String? referralNotes,
  }) {
    return {
      'targetDoctorId': targetDoctorId,
      'patientId': patientId,
      'reason': reason,
      'specialty': specialty,
      'urgency': urgency,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (symptoms != null) 'symptoms': symptoms,
      if (relevantHistory != null) 'relevantHistory': relevantHistory,
      if (currentMedications != null) 'currentMedications': currentMedications,
      if (specificConcerns != null) 'specificConcerns': specificConcerns,
      if (attachedDocuments != null) 'attachedDocuments': attachedDocuments,
      'includeFullHistory': includeFullHistory,
      if (preferredDates != null)
        'preferredDates': preferredDates.map((d) => d.toIso8601String()).toList(),
      if (referralNotes != null) 'referralNotes': referralNotes,
    };
  }

  /// Create ReferralModel from entity
  factory ReferralModel.fromEntity(ReferralEntity entity) {
    return ReferralModel(
      id: entity.id,
      referringDoctorId: entity.referringDoctorId,
      targetDoctorId: entity.targetDoctorId,
      patientId: entity.patientId,
      referralDate: entity.referralDate,
      reason: entity.reason,
      urgency: entity.urgency,
      specialty: entity.specialty,
      diagnosis: entity.diagnosis,
      symptoms: entity.symptoms,
      relevantHistory: entity.relevantHistory,
      currentMedications: entity.currentMedications,
      specificConcerns: entity.specificConcerns,
      attachedDocuments: entity.attachedDocuments,
      status: entity.status,
      statusHistory: entity.statusHistory,
      includeFullHistory: entity.includeFullHistory,
      appointmentDate: entity.appointmentDate,
      appointmentTime: entity.appointmentTime,
      appointmentId: entity.appointmentId,
      preferredDates: entity.preferredDates,
      referralNotes: entity.referralNotes,
      responseNotes: entity.responseNotes,
      completionNotes: entity.completionNotes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      referringDoctorName: entity.referringDoctorName,
      referringDoctorSpecialty: entity.referringDoctorSpecialty,
      targetDoctorName: entity.targetDoctorName,
      targetDoctorSpecialty: entity.targetDoctorSpecialty,
      patientName: entity.patientName,
      patientPhone: entity.patientPhone,
    );
  }
}
