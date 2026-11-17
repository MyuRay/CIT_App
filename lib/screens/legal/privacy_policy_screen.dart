import 'package:flutter/material.dart';

import '../../core/legal/legal_documents.g.dart';
import 'legal_document_anchor.dart';
import 'legal_document_view.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({
    super.key,
    this.initialAnchor = LegalDocumentAnchor.none,
  });

  final LegalDocumentAnchor initialAnchor;

  @override
  Widget build(BuildContext context) => LegalDocumentView(
    appBarTitle: 'プライバシーポリシー',
    document: privacyDocument,
    initialAnchor: initialAnchor,
  );
}
