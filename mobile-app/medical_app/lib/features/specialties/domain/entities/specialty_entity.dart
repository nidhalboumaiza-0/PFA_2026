import 'package:equatable/equatable.dart';

class SpecialtyEntity extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final String? icon;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SpecialtyEntity({
    this.id,
    required this.name,
    this.description,
    this.icon,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    active,
    createdAt,
    updatedAt,
  ];
}
