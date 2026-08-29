import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../../../shared/widgets/teko_input.dart';
import '../models/contract.dart';
import '../models/contract_failure.dart';
import '../models/contract_status.dart';
import '../providers/contract_pdf_url_provider.dart';
import '../providers/contract_provider.dart';
import '../providers/sign_contract_controller_provider.dart';

/// Vista previa + firma de un contrato — mismo widget para ambos roles, parametrizado por
/// `contract.viewerRole` (ver `openspec/specs/service-contracts.md`). El contenido es el
/// snapshot que arma el backend, inmutable — esta pantalla nunca lo edita.
class ContractPreviewScreen extends ConsumerWidget {
  const ContractPreviewScreen({super.key, required this.contractReferenceId});

  final String contractReferenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contractAsync = ref.watch(contractProvider(contractReferenceId));
    final contract = contractAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contractPreviewTitle)),
      body: AsyncStateView<Contract>(
        isLoading: contractAsync.isLoading,
        hasError: contractAsync.hasError,
        data: contract,
        errorMessage: l10n.contractLoadError,
        builder: (context, contract) => _ContractPreviewBody(
          contractReferenceId: contractReferenceId,
          contract: contract,
        ),
      ),
    );
  }
}

class _ContractPreviewBody extends ConsumerStatefulWidget {
  const _ContractPreviewBody({
    required this.contractReferenceId,
    required this.contract,
  });

  final String contractReferenceId;
  final Contract contract;

  @override
  ConsumerState<_ContractPreviewBody> createState() =>
      _ContractPreviewBodyState();
}

class _ContractPreviewBodyState extends ConsumerState<_ContractPreviewBody> {
  final _fullNameController = TextEditingController();
  bool _accepted = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  bool get _canSign =>
      _accepted && _fullNameController.text.trim().isNotEmpty;

  Future<void> _sign() async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(signContractControllerProvider.notifier)
        .sign(widget.contractReferenceId, _fullNameController.text.trim());
    if (!mounted) return;

    final state = ref.read(signContractControllerProvider);
    if (!state.hasError) return;
    final message = switch (state.error) {
      ContractConflictFailure() => l10n.contractConflictError,
      _ => l10n.contractSignError,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPdf() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final url = await ref.read(
        contractPdfUrlProvider(widget.contractReferenceId).future,
      );
      if (!mounted) return;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contractDownloadPdfError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contract = widget.contract;
    final snapshot = contract.contentSnapshot;
    final signState = ref.watch(signContractControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TekoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.service.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(snapshot.service.categoryName),
                const SizedBox(height: 8),
                Text(snapshot.service.description),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TekoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.budgetOption.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (snapshot.budgetOption.description != null) ...[
                  const SizedBox(height: 4),
                  Text(snapshot.budgetOption.description!),
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.budgetOptionTotal(
                    snapshot.budgetOption.totalPrice.round(),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.contractLineItemsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final item in snapshot.lineItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.description} (${item.quantity})',
                          ),
                        ),
                        Text(item.subtotal.round().toString()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ContractStatusBanner(contract: contract),
          const SizedBox(height: 12),
          if (contract.pdfAvailable)
            TekoButton(
              key: const Key('contract_download_pdf_button'),
              label: l10n.contractDownloadPdfButton,
              onPressed: _openPdf,
            )
          else if (contract.isPendingViewerSignature) ...[
            TekoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.contractSignatureSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.contractDisclaimerText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TekoInput(
                    label: l10n.contractFullNameLabel,
                    controller: _fullNameController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      key: const Key('contract_accept_checkbox'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _accepted,
                      onChanged: (value) =>
                          setState(() => _accepted = value ?? false),
                      title: Text(l10n.contractAcceptCheckboxLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TekoButton(
                    key: const Key('contract_sign_button'),
                    label: l10n.contractSignButton,
                    loading: signState.isLoading,
                    onPressed: _canSign && !signState.isLoading ? _sign : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractStatusBanner extends StatelessWidget {
  const _ContractStatusBanner({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, text) = switch (contract.status) {
      ContractStatus.signed => (Icons.verified_outlined, l10n.contractStatusSigned),
      _ => contract.isPendingViewerSignature
          ? (Icons.edit_note_outlined, l10n.contractStatusPendingYourSignature)
          : (
              Icons.hourglass_empty_outlined,
              l10n.contractStatusPendingOtherPartySignature,
            ),
    };

    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
