import 'package:equatable/equatable.dart';

/// Document type enum matching backend schema
enum DocumentType {
  medicalRecord,
  labResult,
  prescription,
  imaging,
  referralLetter,
  other;

  static DocumentType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'medical_record':
        return DocumentType.medicalRecord;
      case 'lab_result':
        return DocumentType.labResult;
      case 'prescription':
        return DocumentType.prescription;
      case 'imaging':
        return DocumentType.imaging;
      case 'referral_letter':
        return DocumentType.referralLetter;
      default:
        return DocumentType.other;
    }
  }

  String get value {
    switch (this) {
      case DocumentType.medicalRecord:
        return 'medical_record';
      case DocumentType.labResult:
        return 'lab_result';
      case DocumentType.prescription:
        return 'prescription';
      case DocumentType.imaging:
        return 'imaging';
      case DocumentType.referralLetter:
        return 'referral_letter';
      case DocumentType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentType.medicalRecord:
        return 'Medical Record';
      case DocumentType.labResult:
        return 'Lab Result';
      case DocumentType.prescription:
        return 'Prescription';
      case DocumentType.imaging:
        return 'Imaging/X-Ray';
      case DocumentType.referralLetter:
        return 'Referral Letter';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DocumentType.medicalRecord:
        return '📋';
      case DocumentType.labResult:
        return '🧪';
      case DocumentType.prescription:
        return '💊';
      case DocumentType.imaging:
        return '🩻';
      case DocumentType.referralLetter:
        return '📄';
      case DocumentType.other:
        return '📎';
    }
  }
}

/// Entity representing a document attached to an appointment
class AppointmentDocumentEntity extends Equatable {
  final String? id;
  final String name;
  final String url;
  final DocumentType type;
  final String? description;
  final DateTime? uploadedAt;

  const AppointmentDocumentEntity({
    this.id,
    required this.name,
    required this.url,
    this.type = DocumentType.other,
    this.description,
    this.uploadedAt,
  });

  /// Check if document is an image (checks both URL and filename)
  bool get isImage {
    // Check URL first (removing query params)
    final urlWithoutParams = url.split('?').first.toLowerCase();
    if (_isImageExtension(urlWithoutParams)) return true;
    
    // Also check filename
    final lowerName = name.toLowerCase();
    return _isImageExtension(lowerName);
  }

  bool _isImageExtension(String path) {
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.endsWith('.bmp');
  }

  /// Check if document is a PDF (checks both URL and filename)
  bool get isPdf {
    final urlWithoutParams = url.split('?').first.toLowerCase();
    final lowerName = name.toLowerCase();
    return urlWithoutParams.endsWith('.pdf') || lowerName.endsWith('.pdf');
  }

  /// Get file extension from URL or name
  String get extension {
    // Try URL first (without query params)
    final urlWithoutParams = url.split('?').first;
    final urlParts = urlWithoutParams.split('.');
    if (urlParts.length > 1) {
      return urlParts.last.toLowerCase();
    }
    // Fallback to name
    final nameParts = name.split('.');
    return nameParts.length > 1 ? nameParts.last.toLowerCase() : '';
  }

  @override
  List<Object?> get props => [id, name, url, type, description, uploadedAt];
}

/// Model for creating a new document attachment (before upload)
class PendingDocumentAttachment {
  final String localPath;
  final String fileName;
  final DocumentType type;
  final String? description;
  final int fileSize; // in bytes

  PendingDocumentAttachment({
    required this.localPath,
    required this.fileName,
    this.type = DocumentType.other,
    this.description,
    this.fileSize = 0,
  });

  /// Get human-readable file size
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if file is an image
  bool get isImage {
    final lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp');
  }

  /// Check if file is a PDF
  bool get isPdf {
    return fileName.toLowerCase().endsWith('.pdf');
  }
}
