import 'package:medical_app/features/specialties/domain/entities/specialty_entity.dart';

class SpecialtyModel extends SpecialtyEntity {
  const SpecialtyModel({
    String? id,
    required String name,
    String? description,
    String? icon,
    bool active = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
         id: id,
         name: name,
         description: description,
         icon: icon,
         active: active,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
