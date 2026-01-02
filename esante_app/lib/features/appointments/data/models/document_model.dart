import '../../domain/entities/document_entity.dart';

/// Data model for appointment document from API
class AppointmentDocumentModel extends AppointmentDocumentEntity {
  const AppointmentDocumentModel({
    super.id,
    required super.name,
    required super.url,
    super.type,
    super.description,
    super.uploadedAt,
  });

  /// Create from JSON response
  factory AppointmentDocumentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDocumentModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name'] ?? 'Unnamed Document',
      url: json['url'] ?? '',
      type: DocumentType.fromString(json['type'] ?? 'other'),
      description: json['description'],
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'])
          : null,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'type': type.value,
      if (description != null && description!.isNotEmpty) 
        'description': description,
    };
  }

  /// Create from entity
  factory AppointmentDocumentModel.fromEntity(AppointmentDocumentEntity entity) {
    return AppointmentDocumentModel(
      id: entity.id,
      name: entity.name,
      url: entity.url,
      type: entity.type,
      description: entity.description,
      uploadedAt: entity.uploadedAt,
    );
  }

  /// Convert to entity
  AppointmentDocumentEntity toEntity() {
    return AppointmentDocumentEntity(
      id: id,
      name: name,
      url: url,
      type: type,
      description: description,
      uploadedAt: uploadedAt,
    );
  }
}

/// Response model for document list
class AppointmentDocumentsResponse {
  final String appointmentId;
  final List<AppointmentDocumentModel> documents;
  final int totalDocuments;

  AppointmentDocumentsResponse({
    required this.appointmentId,
    required this.documents,
    required this.totalDocuments,
  });

  factory AppointmentDocumentsResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentDocumentsResponse(
      appointmentId: json['appointmentId'] ?? '',
      documents: (json['documents'] as List? ?? [])
          .map((doc) => AppointmentDocumentModel.fromJson(doc))
          .toList(),
      totalDocuments: json['totalDocuments'] ?? 0,
    );
  }
}

/// Response model for add document operation
class AddDocumentResponse {
  final String message;
  final AppointmentDocumentModel document;
  final int totalDocuments;

  AddDocumentResponse({
    required this.message,
    required this.document,
    required this.totalDocuments,
  });

  factory AddDocumentResponse.fromJson(Map<String, dynamic> json) {
    return AddDocumentResponse(
      message: json['message'] ?? 'Document added successfully',
      document: AppointmentDocumentModel.fromJson(json['document'] ?? {}),
      totalDocuments: json['totalDocuments'] ?? 0,
    );
  }
}
