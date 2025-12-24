import 'package:equatable/equatable.dart';

class MedicalFileEntity extends Equatable {
  final String id;
  final String filename;
  final String originalName;
  final String path;
  final String mimetype;
  final int size;
  final String description;
  final DateTime createdAt;

  const MedicalFileEntity({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.path,
    required this.mimetype,
    required this.size,
    required this.description,
    required this.createdAt,
  });

  bool get isImage => mimetype.startsWith('image/');
  bool get isPdf => mimetype == 'application/pdf';

  String get fileType {
    if (isImage) return 'Image';
    if (isPdf) return 'PDF';
    return 'Document';
  }

  String get fileSize {
    if (size < 1024) return '$size B';
    if (size < 1048576) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1048576).toStringAsFixed(1)} MB';
  }

  String get displayName => originalName.isNotEmpty ? originalName : filename;

  @override
  List<Object?> get props => [
    id,
    filename,
    originalName,
    path,
    mimetype,
    size,
    description,
    createdAt,
  ];
}
