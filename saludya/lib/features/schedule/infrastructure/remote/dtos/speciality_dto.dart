class SpecialityDto {
  final int id;
  final String name;
  final String description;

  const SpecialityDto({
    required this.id,
    required this.name,
    required this.description,
  });

  factory SpecialityDto.fromJson(Map<String, dynamic> json) {
    return SpecialityDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}
