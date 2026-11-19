import 'package:equatable/equatable.dart';

class TeamEntity extends Equatable {
  final String id;
  final String name;
  final int colorValue;
  final String? logoPath;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamEntity({
    required this.id,
    required this.name,
    required this.colorValue,
    this.logoPath,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  TeamEntity copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? logoPath,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      logoPath: logoPath ?? this.logoPath,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        colorValue,
        logoPath,
        isArchived,
        createdAt,
        updatedAt,
      ];
}

