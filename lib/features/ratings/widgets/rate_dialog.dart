import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Diálogo genérico de 1-5 estrellas + comentario opcional — reusado tanto para "cliente califica
/// profesional" como "profesional califica cliente". Solo recolecta el input; quien lo llama
/// decide a qué endpoint mandarlo (ver `service_detail_screen.dart`/`professional_services_screen.dart`).
Future<(double rating, String? comment)?> showRateDialog(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  final commentController = TextEditingController();
  var selectedStars = 0;

  return showDialog<(double, String?)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(l10n.ratingDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      key: Key('rate_star_$star'),
                      icon: Icon(
                        star <= selectedStars ? Icons.star : Icons.star_border,
                      ),
                      onPressed: () => setState(() => selectedStars = star),
                    ),
                ],
              ),
              TextField(
                key: const Key('rate_comment_field'),
                controller: commentController,
                decoration: InputDecoration(labelText: l10n.ratingCommentLabel),
              ),
              if (selectedStars == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.ratingRequired,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ratingCancelButton),
            ),
            TextButton(
              key: const Key('rate_dialog_submit_button'),
              onPressed: selectedStars == 0
                  ? null
                  : () {
                      final comment = commentController.text.trim();
                      final result = (
                        selectedStars.toDouble(),
                        comment.isEmpty ? null : comment,
                      );
                      Navigator.of(context).pop(result);
                    },
              child: Text(l10n.ratingSubmitButton),
            ),
          ],
        );
      },
    ),
  );
}
