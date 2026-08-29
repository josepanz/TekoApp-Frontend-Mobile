import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/document_category.dart';
import '../models/document_review_status.dart';
import '../models/my_document_status.dart';
import '../providers/my_documents_provider.dart';
import 'upload_document_sheet.dart';

/// "Mis documentos" (profesional) — un tipo aplicable por fila, agrupado por categoría, con badge
/// de estado y botón de subir/volver a subir. Ver
/// `openspec/changes/0007-professional-documents-and-background-checks.md`.
class MyDocumentsScreen extends ConsumerWidget {
  const MyDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final documentsAsync = ref.watch(myDocumentsProvider);
    final statuses = documentsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myDocumentsScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncStateView<List<MyDocumentStatus>>(
          isLoading: documentsAsync.isLoading,
          hasError: documentsAsync.hasError,
          data: statuses,
          isEmpty: statuses != null && statuses.isEmpty,
          errorMessage: l10n.myDocumentsError,
          emptyMessage: l10n.myDocumentsEmpty,
          builder: (context, statuses) => _GroupedByCategory(statuses: statuses),
        ),
      ),
    );
  }
}

class _GroupedByCategory extends StatelessWidget {
  const _GroupedByCategory({required this.statuses});

  final List<MyDocumentStatus> statuses;

  String _categoryLabel(AppLocalizations l10n, DocumentCategory category) {
    return switch (category) {
      DocumentCategory.backgroundCheck => l10n.documentCategoryBackgroundCheck,
      DocumentCategory.qualification => l10n.documentCategoryQualification,
      DocumentCategory.portfolio => l10n.documentCategoryPortfolio,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byCategory = <DocumentCategory, List<MyDocumentStatus>>{};
    for (final status in statuses) {
      byCategory.putIfAbsent(status.documentType.category, () => []).add(status);
    }

    return ListView(
      children: [
        for (final entry in byCategory.entries) ...[
          Text(
            _categoryLabel(l10n, entry.key),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final status in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DocumentStatusRow(status: status),
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _DocumentStatusRow extends StatelessWidget {
  const _DocumentStatusRow({required this.status});

  final MyDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final document = status.document;
    final type = status.documentType;

    final canUpload = document == null ||
        document.status == DocumentReviewStatus.rejected ||
        document.status == DocumentReviewStatus.expired;

    return TekoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(type.name)),
                    if (type.isRequired)
                      TekoBadge(
                        label: l10n.documentRequiredLabel,
                        variant: TekoBadgeVariant.info,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _StatusBadge(status: document?.status),
                if (document?.status == DocumentReviewStatus.rejected &&
                    document?.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    document!.rejectionReason!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (canUpload)
            TekoButton(
              key: Key('upload_document_button_${type.referenceId}'),
              label: document == null
                  ? l10n.documentUploadButton
                  : l10n.documentReuploadButton,
              variant: TekoButtonVariant.outline,
              onPressed: () =>
                  showUploadDocumentSheet(context, documentType: type),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DocumentReviewStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (status == null) {
      return TekoBadge(label: l10n.documentStatusMissing);
    }
    return switch (status!) {
      DocumentReviewStatus.pending => TekoBadge(
          label: l10n.documentStatusPending,
          variant: TekoBadgeVariant.warning,
        ),
      DocumentReviewStatus.approved => TekoBadge(
          label: l10n.documentStatusApproved,
          variant: TekoBadgeVariant.success,
        ),
      DocumentReviewStatus.rejected => TekoBadge(
          label: l10n.documentStatusRejected,
          variant: TekoBadgeVariant.destructive,
        ),
      DocumentReviewStatus.expired => TekoBadge(
          label: l10n.documentStatusExpired,
          variant: TekoBadgeVariant.destructive,
        ),
    };
  }
}
