class LegalSection {
  const LegalSection({required this.title, required this.body, this.anchor});
  final String title;
  final String body;
  final String? anchor;
}

class LegalDocument {
  const LegalDocument({required this.title, required this.sections});
  final String title;
  final List<LegalSection> sections;
}
