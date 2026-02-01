class Contributor {
  final String docId;
  final String firstName;
  final String lastName;
  final String title;
  final String company;
  final String email;
  final String linkedinUrl;
  final String category;
  final String outboundEmail;
  final String status;

  const Contributor({
    this.docId = '',
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.company,
    required this.email,
    required this.linkedinUrl,
    required this.category,
    this.outboundEmail = '',
    this.status = '',
  });

  String get fullName => '$firstName $lastName';
}
