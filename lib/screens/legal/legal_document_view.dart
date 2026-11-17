import 'package:flutter/material.dart';

import '../../core/legal/legal_document.dart';
import '../../core/legal/legal_documents.g.dart';
import 'legal_document_anchor.dart';

/// App and public Markdown use the same generated document.
class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView({
    super.key,
    required this.appBarTitle,
    required this.document,
    this.initialAnchor = LegalDocumentAnchor.none,
  });

  final String appBarTitle;
  final LegalDocument document;
  final LegalDocumentAnchor initialAnchor;

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  final _anchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialAnchor == LegalDocumentAnchor.chibaChannel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _anchorKey.currentContext;
        if (target == null) return;
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.08,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.document.title, style: theme.textTheme.titleLarge),
              if (legalDocumentEffectiveDate.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('施行日：$legalDocumentEffectiveDate'),
              ],
              const SizedBox(height: 8),
              Text(
                '最終更新日：$legalDocumentUpdated',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              for (final section in widget.document.sections) ...[
                const SizedBox(height: 24),
                Text(
                  section.title,
                  key: section.anchor == 'chibaChannel' ? _anchorKey : null,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  section.body,
                  style: const TextStyle(height: 1.6),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
