// Domain - Entities
export 'domain/entities/consultation_entity.dart';
export 'domain/entities/medical_document_entity.dart';

// Domain - Repositories
export 'domain/repositories/medical_records_repository.dart';

// Data - Models
export 'data/models/consultation_model.dart';
export 'data/models/medical_document_model.dart';

// Data - Data Sources
export 'data/datasources/medical_records_remote_datasource.dart';

// Data - Repository Implementations
export 'data/repositories/medical_records_repository_impl.dart';

// Presentation - BLoC
export 'presentation/bloc/medical_records_bloc.dart';

// Presentation - Pages
export 'presentation/pages/doctor_consultations_page.dart';
export 'presentation/pages/consultation_details_page.dart';
export 'presentation/pages/create_consultation_page.dart';
export 'presentation/pages/patient_medical_history_page.dart';
export 'presentation/pages/documents_page.dart';
