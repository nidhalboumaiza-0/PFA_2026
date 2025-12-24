import 'package:medical_app/features/medical_records/domain/entities/medical_document_entity.dart';

/// Model for medical document with JSON serialization
class MedicalDocumentModel extends MedicalDocumentEntity {
  const MedicalDocumentModel({
    super.id,
    required super.patientId,
    required super.uploadedBy,
    required super.uploaderType,
    super.uploaderDoctorId,
    super.consultationId,
    required super.documentType,
    required super.title,
    super.description,
    required super.fileName,
    required super.fileSize,
    required super.mimeType,
    required super.fileExtension,
    super.s3Key,
    super.s3Bucket,
    super.s3Url,
    super.documentDate,
    super.uploadDate,
    super.isSharedWithAllDoctors,
    super.sharedWithDoctors,
    super.tags,
    super.status,
    super.createdAt,
    super.updatedAt,
    super.uploaderName,
    super.patientName,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json) {
    // Extract patient info
    String patientId = '';
    String? patientName;
    if (json['patientId'] is String) {
      patientId = json['patientId'];
    } else if (json['patientId'] is Map) {
      patientId = json['patientId']['_id'] ?? '';
      patientName =
          '${json['patientId']['nom'] ?? ''} ${json['patientId']['prenom'] ?? ''}'
              .trim();
    }

    // Extract uploader info
    String? uploaderName;
    if (json['uploadedBy'] is Map) {
      uploaderName =
          '${json['uploadedBy']['nom'] ?? ''} ${json['uploadedBy']['prenom'] ?? ''}'
              .trim();
    }

    return MedicalDocumentModel(
      id: json['_id'] ?? json['id'],
      patientId: patientId,
      uploadedBy: json['uploadedBy'] is String
          ? json['uploadedBy']
          : json['uploadedBy']?['_id'] ?? '',
      uploaderType: json['uploaderType'] ?? 'patient',
      uploaderDoctorId: json['uploaderDoctorId'] is String
          ? json['uploaderDoctorId']
          : json['uploaderDoctorId']?['_id'],
      consultationId: json['consultationId'] is String
          ? json['consultationId']
          : json['consultationId']?['_id'],
      documentType: json['documentType'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'],
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? 'application/octet-stream',
      fileExtension: json['fileExtension'] ?? '',
      s3Key: json['s3Key'],
      s3Bucket: json['s3Bucket'],
      s3Url: json['s3Url'],
      documentDate: DateTime.tryParse(json['documentDate'] ?? ''),
      uploadDate: DateTime.tryParse(json['uploadDate'] ?? ''),
      isSharedWithAllDoctors: json['isSharedWithAllDoctors'] ?? true,
      sharedWithDoctors: json['sharedWithDoctors'] != null
          ? List<String>.from(json['sharedWithDoctors'].map((d) =>
              d is String ? d : d['_id']?.toString() ?? ''))
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      status: json['status'] ?? 'active',
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      uploaderName: uploaderName,
      patientName: patientName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'patientId': patientId,
      'uploadedBy': uploadedBy,
      'uploaderType': uploaderType,
      if (uploaderDoctorId != null) 'uploaderDoctorId': uploaderDoctorId,
      if (consultationId != null) 'consultationId': consultationId,
      'documentType': documentType,
      'title': title,
      if (description != null) 'description': description,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
      if (s3Key != null) 's3Key': s3Key,
      if (s3Bucket != null) 's3Bucket': s3Bucket,
      if (s3Url != null) 's3Url': s3Url,
      if (documentDate != null) 'documentDate': documentDate!.toIso8601String(),
      if (uploadDate != null) 'uploadDate': uploadDate!.toIso8601String(),
      'isSharedWithAllDoctors': isSharedWithAllDoctors,
      if (sharedWithDoctors != null) 'sharedWithDoctors': sharedWithDoctors,
      if (tags != null) 'tags': tags,
      'status': status,
    };
  }
}

/// Model for document statistics
class DocumentStatisticsModel extends DocumentStatisticsEntity {
  const DocumentStatisticsModel({
    required super.totalDocuments,
    required super.activeDocuments,
    required super.archivedDocuments,
    super.documentsByType,
    required super.totalStorageBytes,
  });

  factory DocumentStatisticsModel.fromJson(Map<String, dynamic> json) {
    Map<String, int>? byType;
    if (json['documentsByType'] != null) {
      byType = Map<String, int>.from(
        (json['documentsByType'] as Map).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      );
    }

    return DocumentStatisticsModel(
      totalDocuments: json['totalDocuments'] ?? 0,
      activeDocuments: json['activeDocuments'] ?? 0,
      archivedDocuments: json['archivedDocuments'] ?? 0,
      documentsByType: byType,
      totalStorageBytes: json['totalStorageBytes'] ?? 0,
    );
  }
}
