class Advisor {
  final String docId;
  final String firstName;
  final String lastName;
  final String university;
  final String email;
  final String status;

  const Advisor({
    this.docId = '',
    required this.firstName,
    required this.lastName,
    required this.university,
    required this.email,
    this.status = '',
  });

  String get fullName => '$firstName $lastName';
}
