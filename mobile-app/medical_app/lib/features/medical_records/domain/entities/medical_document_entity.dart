import 'package:equatable/equatable.dart';

/// Entity representing a medical document
class MedicalDocumentEntity extends Equatable {
  final String? id;
  final String patientId;
  final String uploadedBy;
  final String uploaderType; // 'patient', 'doctor'
  final String? uploaderDoctorId;
  final String? consultationId;
  final String documentType; // 'lab_result', 'imaging', 'prescription', 'insurance', 'medical_report', 'other'
  final String title;
  final String? description;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String fileExtension;
  final String? s3Key;
  final String? s3Bucket;
  final String? s3Url;
  final DateTime? documentDate;
  final DateTime? uploadDate;
  final bool isSharedWithAllDoctors;
  final List<String>? sharedWithDoctors;
  final List<String>? tags;
  final String status; // 'active', 'archived', 'deleted'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated data for display
  final String? uploaderName;
  final String? patientName;

  const MedicalDocumentEntity({
    this.id,
    required this.patientId,
    required this.uploadedBy,
    required this.uploaderType,
    this.uploaderDoctorId,
    this.consultationId,
    required this.documentType,
    required this.title,
    this.description,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.fileExtension,
    this.s3Key,
    this.s3Bucket,
    this.s3Url,
    this.documentDate,
    this.uploadDate,
    this.isSharedWithAllDoctors = true,
    this.sharedWithDoctors,
    this.tags,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.uploaderName,
    this.patientName,
  });

  /// Get document type display name
  String get documentTypeDisplay {
    switch (documentType) {
      case 'lab_result':
        return 'Résultat de laboratoire';
      case 'imaging':
        return 'Imagerie médicale';
      case 'prescription':
        return 'Ordonnance';
      case 'insurance':
        return 'Assurance';
      case 'medical_report':
        return 'Rapport médical';
      case 'other':
        return 'Autre';
      default:
        return documentType;
    }
  }

  /// Get file size formatted
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if document is an image
  bool get isImage =>
      mimeType.startsWith('image/') ||
      ['jpg', 'jpeg', 'png'].contains(fileExtension.toLowerCase());

  /// Check if document is a PDF
  bool get isPdf =>
      mimeType == 'application/pdf' ||
      fileExtension.toLowerCase() == 'pdf';

  @override
  List<Object?> get props => [
        id,
        patientId,
        uploadedBy,
        uploaderType,
        uploaderDoctorId,
        consultationId,
        documentType,
        title,
        description,
        fileName,
        fileSize,
        mimeType,
        fileExtension,
        s3Key,
        s3Bucket,
        s3Url,
        documentDate,
        uploadDate,
        isSharedWithAllDoctors,
        sharedWithDoctors,
        tags,
        status,
        createdAt,
        updatedAt,
      ];
}

/// Document type enum for UI
enum DocumentType {
  labResult,
  imaging,
  prescription,
  insurance,
  medicalReport,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get value {
    switch (this) {
      case DocumentType.labResult:
        return 'lab_result';
      case DocumentType.imaging:
        return 'imaging';
      case DocumentType.prescription:
        return 'prescription';
      case DocumentType.insurance:
        return 'insurance';
      case DocumentType.medicalReport:
        return 'medical_report';
      case DocumentType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentType.labResult:
        return 'Résultat de laboratoire';
      case DocumentType.imaging:
        return 'Imagerie médicale';
      case DocumentType.prescription:
        return 'Ordonnance';
      case DocumentType.insurance:
        return 'Assurance';
      case DocumentType.medicalReport:
        return 'Rapport médical';
      case DocumentType.other:
        return 'Autre';
    }
  }

  static DocumentType fromString(String value) {
    switch (value) {
      case 'lab_result':
        return DocumentType.labResult;
      case 'imaging':
        return DocumentType.imaging;
      case 'prescription':
        return DocumentType.prescription;
      case 'insurance':
        return DocumentType.insurance;
      case 'medical_report':
        return DocumentType.medicalReport;
      case 'other':
      default:
        return DocumentType.other;
    }
  }
}

/// Entity representing document statistics
class DocumentStatisticsEntity extends Equatable {
  final int totalDocuments;
  final int activeDocuments;
  final int archivedDocuments;
  final Map<String, int>? documentsByType;
  final int totalStorageBytes;

  const DocumentStatisticsEntity({
    required this.totalDocuments,
    required this.activeDocuments,
    required this.archivedDocuments,
    this.documentsByType,
    required this.totalStorageBytes,
  });

  String get totalStorageFormatted {
    if (totalStorageBytes < 1024) {
      return '$totalStorageBytes B';
    } else if (totalStorageBytes < 1024 * 1024) {
      return '${(totalStorageBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalStorageBytes < 1024 * 1024 * 1024) {
      return '${(totalStorageBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalStorageBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  List<Object?> get props => [
        totalDocuments,
        activeDocuments,
        archivedDocuments,
        documentsByType,
        totalStorageBytes,
      ];
}
