class Contributor {
  final String docId;
  final String firstName;
  final String lastName;
  final String title;
  final String company;
  final String email;
  final String linkedinUrl;
  final String category;

  const Contributor({
    this.docId = '',
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.company,
    required this.email,
    required this.linkedinUrl,
    required this.category,
  });

  String get fullName => '$firstName $lastName';
}
