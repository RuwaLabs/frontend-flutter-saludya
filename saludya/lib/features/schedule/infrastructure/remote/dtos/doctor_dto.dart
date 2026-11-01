class DoctorDto {
  final int id;
  final int specialityId;
  final String name;
  final String lastname;

  const DoctorDto({
    required this.id,
    required this.specialityId,
    required this.name,
    required this.lastname,
  });

  factory DoctorDto.fromJson(Map<String, dynamic> json) {
    return DoctorDto(
      id: json['id'] as int,
      specialityId: json['specialtyId'] as int,
      name: json['name'] as String,
      lastname: json['lastname'] as String,
    );
  }
}
