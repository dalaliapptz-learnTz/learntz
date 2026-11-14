import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import 'curriculum_document_file.dart';
import 'curriculum_models.dart';
import 'curriculum_providers.dart';

class CurriculumAdminScreen extends ConsumerWidget {
  const CurriculumAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final capabilities = ref.watch(curriculumStaffCapabilitiesProvider);

    return capabilities.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(24),
        child: AuthInlineMessage(message: error.toString(), isError: true),
      ),
      data: (value) => value.canAccess
          ? const _CurriculumPilotPanel()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: AppCard(
                child: Text(
                  l10n.curriculumAccessDenied,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
    );
  }
}

class _CurriculumPilotPanel extends ConsumerStatefulWidget {
  const _CurriculumPilotPanel();

  @override
  ConsumerState<_CurriculumPilotPanel> createState() =>
      _CurriculumPilotPanelState();
}

class _CurriculumPilotPanelState extends ConsumerState<_CurriculumPilotPanel> {
  bool _isImporting = false;
  String? _error;

  Future<void> _refresh() async {
    ref.invalidate(curriculumPilotProvider);
    await ref.read(curriculumPilotProvider.future);
  }

  Future<void> _verifySource(CurriculumSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final note = await _requestNote(
      title: l10n.curriculumVerifyAction,
      label: l10n.curriculumReviewNoteLabel,
      requiredNote: false,
    );
    if (note == null || !mounted) return;

    try {
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      await repository.verifySource(
        sourceId: source.id,
        verified: true,
        note: note,
      );
      await _refresh();
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _reviewRights(CurriculumSource source) async {
    final result = await showDialog<_RightsDecision>(
      context: context,
      builder: (context) => const _RightsDecisionDialog(),
    );
    if (result == null || !mounted) return;

    try {
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      await repository.reviewSourceRights(
        sourceId: source.id,
        status: result.status,
        note: result.note,
        evidenceUrl: result.evidenceUrl,
      );
      await _refresh();
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _importDocument({
    required CurriculumSource source,
    required CurriculumVersion version,
  }) async {
    if (!source.canImport) {
      _showError(
        StateError(AppLocalizations.of(context)!.curriculumRightsWarning),
      );
      return;
    }
    setState(() {
      _isImporting = true;
      _error = null;
    });

    CurriculumImportJob? job;
    try {
      final contentType = source.documentFormat;
      final extensionsByType = {
        for (final entry in CurriculumDocumentFile.contentTypes.entries)
          entry.value: entry.key,
      };
      final extension = contentType == null
          ? null
          : extensionsByType[contentType];
      if (contentType == null || extension == null) {
        throw const FormatException(
          'This source document format is not supported.',
        );
      }
      final file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Curriculum source document',
            extensions: [extension],
          ),
        ],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      CurriculumDocumentFile.validate(
        bytes: bytes,
        filename: file.name,
        expectedContentType: contentType,
      );
      final checksum = CurriculumDocumentFile.checksum(bytes);
      if (checksum != source.checksum) {
        throw const FormatException(
          'The selected document checksum does not match the reviewed source record.',
        );
      }
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      job = await repository.registerImport(
        versionId: version.id,
        sourceId: source.id,
        checksum: checksum,
        documentFormat: contentType,
        filename: file.name,
        fileSizeBytes: bytes.length,
      );
      if (!['queued', 'failed'].contains(job.status) || job.uploadComplete) {
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.curriculumImportAlreadyRegistered,
              ),
            ),
          );
        }
        return;
      }
      await repository.uploadSourceDocument(job: job, bytes: bytes);
      await repository.markImportUploaded(job.id);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.curriculumImportSucceeded,
            ),
          ),
        );
      }
    } on Exception catch (error) {
      var message = error.toString();
      if (job != null) ref.invalidate(curriculumPilotProvider);
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<String?> _requestNote({
    required String title,
    required String label,
    required bool requiredNote,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _NoteDialog(title: title, label: label, requiredNote: requiredNote),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() => _error = error.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = ref.watch(curriculumPilotProvider);
    final capabilities = ref.watch(curriculumStaffCapabilitiesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: snapshot.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => AppCard(
              child: AuthInlineMessage(
                message: error.toString(),
                isError: true,
              ),
            ),
            data: (pilot) {
              final staff = capabilities.asData?.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.curriculumAdminTitle,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.curriculumAdminDescription),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        key: const Key('curriculum-launch-cms-btn'),
                        onPressed: () => context.push('/content/studio'),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Content Studio'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    AuthInlineMessage(message: _error!, isError: true),
                    const SizedBox(height: 12),
                  ],
                  _SourceCard(
                    source: pilot.source,
                    version: pilot.version,
                    capabilities: staff,
                    isImporting: _isImporting,
                    onVerify: () => _verifySource(pilot.source),
                    onReviewRights: () => _reviewRights(pilot.source),
                    onImport: () => _importDocument(
                      source: pilot.source,
                      version: pilot.version,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _VersionCard(
                    version: pilot.version,
                    source: pilot.source,
                    jobs: pilot.jobs,
                    capabilities: staff,
                    onTransition: (status) async {
                      try {
                        final repository = ref.read(
                          curriculumRepositoryProvider,
                        );
                        if (repository == null) {
                          throw const AuthNotConfiguredException();
                        }
                        await repository.transitionVersion(
                          versionId: pilot.version.id,
                          targetStatus: status,
                          note: 'Human curriculum workflow action',
                        );
                        await _refresh();
                      } on Exception catch (error) {
                        _showError(error);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _RightsHistoryCard(events: pilot.rightsHistory),
                  const SizedBox(height: 16),
                  Text(
                    l10n.curriculumImportsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (pilot.jobs.isEmpty)
                    AppCard(child: Text(l10n.curriculumNoImports))
                  else
                    for (final job in pilot.jobs) ...[
                      _ImportJobCard(
                        key: ValueKey(job.id),
                        job: job,
                        version: pilot.version,
                        capabilities: staff,
                        onChanged: _refresh,
                        onError: _showError,
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.version,
    required this.capabilities,
    required this.isImporting,
    required this.onVerify,
    required this.onReviewRights,
    required this.onImport,
  });

  final CurriculumSource source;
  final CurriculumVersion version;
  final CurriculumStaffCapabilities? capabilities;
  final bool isImporting;
  final VoidCallback onVerify;
  final VoidCallback onReviewRights;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.curriculumSourceTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(source.title, style: Theme.of(context).textTheme.titleMedium),
          if (source.documentFormat case final format?) ...[
            const SizedBox(height: 4),
            Text(format, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (source.documentReference case final reference?) ...[
            const SizedBox(height: 4),
            Text(reference),
          ],
          if (source.sourceUrl case final url?) ...[
            const SizedBox(height: 4),
            SelectableText(url),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label:
                    '${l10n.curriculumVerificationLabel}: ${source.verificationStatus}',
              ),
              _StatusChip(
                label:
                    '${l10n.curriculumRightsStatusLabel}: ${_rightsLabel(l10n, source.usageRightsStatus)}',
              ),
              _StatusChip(
                label: '${l10n.curriculumVersionLabel}: ${version.displayName}',
              ),
            ],
          ),
          if (source.checksum case final checksum?) ...[
            const SizedBox(height: 12),
            Text(
              '${l10n.curriculumChecksumLabel}: ${checksum.substring(0, 16)}…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Text(l10n.curriculumRightsWarning),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (capabilities?.canReview == true &&
                  source.verificationStatus == 'unverified')
                OutlinedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.curriculumVerifyAction),
                ),
              if (capabilities?.canReview == true &&
                  source.verificationStatus == 'verified')
                OutlinedButton.icon(
                  onPressed: onReviewRights,
                  icon: const Icon(Icons.policy_outlined),
                  label: Text(l10n.curriculumRightsAction),
                ),
              if (capabilities?.canEdit == true && source.canImport)
                FilledButton.icon(
                  onPressed: isImporting ? null : onImport,
                  icon: isImporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(
                    isImporting
                        ? l10n.curriculumImportProcessing
                        : l10n.curriculumImportAction,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.source,
    required this.jobs,
    required this.capabilities,
    required this.onTransition,
  });

  final CurriculumVersion version;
  final CurriculumSource source;
  final List<CurriculumImportJob> jobs;
  final CurriculumStaffCapabilities? capabilities;
  final ValueChanged<String> onTransition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allReviewed =
        jobs.isNotEmpty && jobs.every((job) => job.status == 'reviewed');
    final hasReviewedContent = jobs.any((job) => job.status == 'reviewed');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.curriculumVersionReviewTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('${l10n.curriculumStatusLabel}: ${version.status}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (capabilities?.canEdit == true &&
                  version.status == 'draft' &&
                  source.canImport &&
                  allReviewed)
                FilledButton(
                  onPressed: () => onTransition('under_review'),
                  child: Text(l10n.curriculumSubmitVersionAction),
                ),
              if (capabilities?.canApprove == true &&
                  version.status == 'under_review' &&
                  hasReviewedContent)
                FilledButton(
                  onPressed: () => onTransition('approved'),
                  child: Text(l10n.curriculumApproveVersionAction),
                ),
              if (capabilities?.canApprove == true &&
                  version.status == 'approved' &&
                  hasReviewedContent)
                FilledButton(
                  onPressed: () => onTransition('published'),
                  child: Text(l10n.curriculumPublishVersionAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RightsHistoryCard extends StatelessWidget {
  const _RightsHistoryCard({required this.events});

  final List<CurriculumSourceRightsEvent> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (events.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.curriculumRightsHistoryTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final event in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_rightsLabel(l10n, event.status)),
              subtitle: Text(event.note),
              trailing: Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(event.createdAt.toLocal()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportJobCard extends ConsumerWidget {
  const _ImportJobCard({
    required this.job,
    required this.version,
    required this.capabilities,
    required this.onChanged,
    required this.onError,
    super.key,
  });

  final CurriculumImportJob job;
  final CurriculumVersion version;
  final CurriculumStaffCapabilities? capabilities;
  final Future<void> Function() onChanged;
  final ValueChanged<Object> onError;

  Future<void> _validate(WidgetRef ref) async {
    try {
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      final result = await repository.validateImport(job.id);
      final errors = (result['errors'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(growable: false);
      if (errors.isNotEmpty) {
        onError(StateError(errors.join('\n')));
      }
      ref.invalidate(curriculumValidationReportProvider(job.id));
      ref.invalidate(curriculumDuplicateMatchesProvider(job.id));
      await onChanged();
      ref.invalidate(curriculumImportItemsProvider(job.id));
    } on Exception catch (error) {
      onError(error);
    }
  }

  Future<void> _reviewDuplicate({
    required BuildContext context,
    required WidgetRef ref,
    required CurriculumDuplicateMatch match,
    required String decision,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _NoteDialog(
        title: l10n.curriculumDuplicateReviewTitle,
        label: l10n.curriculumReviewNoteLabel,
        requiredNote: decision == 'deferred',
      ),
    );
    if (note == null || !context.mounted) return;
    try {
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      await repository.reviewDuplicateMatch(
        matchId: match.id,
        decision: decision,
        note: note,
      );
      ref.invalidate(curriculumDuplicateMatchesProvider(job.id));
      ref.invalidate(curriculumValidationReportProvider(job.id));
      await onChanged();
    } on Exception catch (error) {
      onError(error);
    }
  }

  Future<void> _reprocessPage(WidgetRef ref, int pageNumber) async {
    try {
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      await repository.requestPageReprocess(
        jobId: job.id,
        pageNumber: pageNumber,
      );
      ref.invalidate(curriculumImportPagesProvider(job.id));
      await onChanged();
    } on Exception catch (error) {
      onError(error);
    }
  }

  Future<void> _review({
    required BuildContext context,
    required WidgetRef ref,
    required CurriculumImportItem item,
    required String decision,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _NoteDialog(
        title: decision == 'approved'
            ? l10n.curriculumApproveItemAction
            : l10n.curriculumRejectItemAction,
        label: l10n.curriculumReviewNoteLabel,
        requiredNote: decision == 'rejected',
      ),
    );
    if (note == null || !context.mounted) return;
    try {
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      await repository.reviewImportItem(
        itemId: item.id,
        decision: decision,
        note: note,
      );
      ref.invalidate(curriculumImportItemsProvider(job.id));
      await onChanged();
    } on Exception catch (error) {
      onError(error);
    }
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _AddCurriculumItemDialog(jobId: job.id, version: version),
    );
    if (result != true || !context.mounted) return;
    ref.invalidate(curriculumImportItemsProvider(job.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(curriculumImportItemsProvider(job.id));
    final pages = ref.watch(curriculumImportPagesProvider(job.id));
    final validation = ref.watch(curriculumValidationReportProvider(job.id));
    final duplicateMatches = ref.watch(
      curriculumDuplicateMatchesProvider(job.id),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.curriculumImportJobLabel} ${job.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(label: job.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.curriculumAttemptLabel}: ${job.attemptCount} · '
            '${MaterialLocalizations.of(context).formatMediumDate(job.createdAt.toLocal())}',
          ),
          if (job.validationErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final error in job.validationErrors) Text(error),
          ],
          if (validation.hasValue && validation.value != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.curriculumValidationSummary(
                validation.value!.errorCount,
                validation.value!.warningCount,
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final error in validation.value!.errors)
              ListTile(
                dense: true,
                leading: const Icon(Icons.error_outline),
                title: Text(error),
              ),
            for (final warning in validation.value!.warnings)
              ListTile(
                dense: true,
                leading: const Icon(Icons.warning_amber_outlined),
                title: Text(
                  warning.pageNumber == null
                      ? warning.message
                      : '${l10n.curriculumPageLabel} ${warning.pageNumber}: '
                            '${warning.message}',
                ),
              ),
          ] else if (validation.hasError)
            Text(validation.error.toString()),
          if (duplicateMatches.hasValue &&
              duplicateMatches.value!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.curriculumDuplicateMatchesTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final match in duplicateMatches.value!)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.curriculumDuplicateCandidateLabel}: '
                        '${match.candidateLabel}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${match.matchType} · '
                        '${(match.similarity * 100).round()}%',
                      ),
                      if (match.candidateText.isNotEmpty)
                        Text(
                          match.candidateText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text('${l10n.curriculumStatusLabel}: ${match.decision}'),
                      if (match.reviewNote case final note?) Text(note),
                      if (match.decision == 'pending' &&
                          capabilities?.canReview == true)
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _reviewDuplicate(
                                context: context,
                                ref: ref,
                                match: match,
                                decision: 'not_duplicate',
                              ),
                              child: Text(l10n.curriculumNotDuplicateAction),
                            ),
                            OutlinedButton(
                              onPressed: () => _reviewDuplicate(
                                context: context,
                                ref: ref,
                                match: match,
                                decision: 'deferred',
                              ),
                              child: Text(l10n.curriculumDeferDuplicateAction),
                            ),
                            FilledButton(
                              onPressed: () => _reviewDuplicate(
                                context: context,
                                ref: ref,
                                match: match,
                                decision: 'confirmed_duplicate',
                              ),
                              child: Text(
                                l10n.curriculumConfirmDuplicateAction,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ] else if (duplicateMatches.hasError)
            Text(duplicateMatches.error.toString()),
          if (job.status == 'extracted' ||
              job.status == 'validation_failed') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (capabilities?.canEdit == true)
                  OutlinedButton.icon(
                    onPressed: () => _addItem(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.curriculumAddItemAction),
                  ),
                if (capabilities?.canEdit == true)
                  FilledButton(
                    onPressed: () => _validate(ref),
                    child: Text(l10n.curriculumValidateAction),
                  ),
              ],
            ),
          ],
          if (pages.hasValue)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.curriculumExtractedPages(pages.value!.length)),
              children: [
                for (final page in pages.value!)
                  ListTile(
                    title: Text(
                      '${l10n.curriculumPageLabel} ${page.pageNumber} · '
                      '${page.extractionMethod}'
                      '${page.ocrConfidence == null ? '' : ' · OCR ${(page.ocrConfidence! * 100).round()}%'}',
                    ),
                    subtitle: Text(
                      [
                        page.extractedText.isEmpty
                            ? l10n.curriculumPageNoText
                            : page.extractedText,
                        ...page.extractionWarnings,
                      ].join('\n'),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                        capabilities?.canEdit == true &&
                            [
                              'extracted',
                              'validation_failed',
                              'in_review',
                            ].contains(job.status)
                        ? IconButton(
                            tooltip: l10n.curriculumReprocessPageAction,
                            onPressed: () =>
                                _reprocessPage(ref, page.pageNumber),
                            icon: const Icon(Icons.refresh),
                          )
                        : null,
                  ),
              ],
            )
          else if (pages.hasError)
            Text(pages.error.toString()),
          if (items.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.hasError)
            Text(items.error.toString())
          else
            for (final item in items.value!) ...[
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.officialTerm ?? item.itemType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${l10n.curriculumSourcePageLabel}: '
                    '${_pageNumberFor(item, pages.asData?.value) ?? item.importPageId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.curriculumSourceTextLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SelectableText(item.sourceText),
                  const SizedBox(height: 8),
                  Text(
                    l10n.curriculumNormalizedTextLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SelectableText(item.normalizedText),
                  Text(
                    '${l10n.curriculumStatusLabel}: ${item.reviewStatus}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.reviewNote case final note?) ...[
                    const SizedBox(height: 4),
                    Text(note),
                  ],
                ],
              ),
              if (job.status == 'in_review' &&
                  item.reviewStatus == 'pending' &&
                  capabilities?.canReview == true)
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _review(
                        context: context,
                        ref: ref,
                        item: item,
                        decision: 'rejected',
                      ),
                      child: Text(l10n.curriculumRejectItemAction),
                    ),
                    FilledButton(
                      onPressed: () => _review(
                        context: context,
                        ref: ref,
                        item: item,
                        decision: 'approved',
                      ),
                      child: Text(l10n.curriculumApproveItemAction),
                    ),
                  ],
                ),
            ],
        ],
      ),
    );
  }
}

class _AddCurriculumItemDialog extends ConsumerStatefulWidget {
  const _AddCurriculumItemDialog({required this.jobId, required this.version});

  final String jobId;
  final CurriculumVersion version;

  @override
  ConsumerState<_AddCurriculumItemDialog> createState() =>
      _AddCurriculumItemDialogState();
}

class _AddCurriculumItemDialogState
    extends ConsumerState<_AddCurriculumItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _termController = TextEditingController();
  final _sourceTextController = TextEditingController();
  final _normalizedTextController = TextEditingController();
  String _itemType = 'learning_outcome';
  String? _pageId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _termController.dispose();
    _sourceTextController.dispose();
    _normalizedTextController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pageId == null) {
      setState(() => _error = AppLocalizations.of(context)!.requiredField);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(curriculumRepositoryProvider);
      if (repository == null) throw const AuthNotConfiguredException();
      await repository.addImportItem(
        jobId: widget.jobId,
        versionId: widget.version.id,
        curriculumId: widget.version.curriculumId,
        pageId: _pageId!,
        itemType: _itemType,
        officialTerm: _termController.text.trim().isEmpty
            ? null
            : _termController.text.trim(),
        sourceText: _sourceTextController.text,
        normalizedText: _normalizedTextController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = ref.watch(curriculumImportPagesProvider(widget.jobId));

    return AlertDialog(
      title: Text(l10n.curriculumAddItemAction),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  AuthInlineMessage(message: _error!, isError: true),
                pages.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => AuthInlineMessage(
                    message: error.toString(),
                    isError: true,
                  ),
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: _pageId,
                    decoration: InputDecoration(
                      labelText: l10n.curriculumSourcePageLabel,
                    ),
                    items: [
                      for (final page in items)
                        DropdownMenuItem(
                          value: page.id,
                          child: Text(
                            '${l10n.curriculumPageLabel} ${page.pageNumber}',
                          ),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? l10n.requiredField : null,
                    onChanged: (value) => setState(() => _pageId = value),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _itemType,
                  decoration: InputDecoration(
                    labelText: l10n.curriculumItemTypeLabel,
                  ),
                  items:
                      const [
                            'subject',
                            'learning_area',
                            'topic',
                            'strand',
                            'subtopic',
                            'sub_strand',
                            'competency',
                            'learning_outcome',
                            'assessment_guidance',
                            'teaching_guidance',
                            'other',
                          ]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _itemType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _termController,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: l10n.curriculumOfficialTermLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sourceTextController,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 20000,
                  decoration: InputDecoration(
                    labelText: l10n.curriculumSourceTextLabel,
                  ),
                  validator: (value) => _requiredText(value, l10n),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _normalizedTextController,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 20000,
                  decoration: InputDecoration(
                    labelText: l10n.curriculumNormalizedTextLabel,
                  ),
                  validator: (value) => _requiredText(value, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: _saving || pages.isLoading ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.curriculumAddItemAction),
        ),
      ],
    );
  }
}

class _RightsDecision {
  const _RightsDecision({
    required this.status,
    required this.note,
    required this.evidenceUrl,
  });

  final String status;
  final String note;
  final String? evidenceUrl;
}

class _RightsDecisionDialog extends StatefulWidget {
  const _RightsDecisionDialog();

  @override
  State<_RightsDecisionDialog> createState() => _RightsDecisionDialogState();
}

class _RightsDecisionDialogState extends State<_RightsDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _evidenceController = TextEditingController();
  String _status = 'permission_pending';

  @override
  void dispose() {
    _noteController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _RightsDecision(
        status: _status,
        note: _noteController.text.trim(),
        evidenceUrl: _evidenceController.text.trim().isEmpty
            ? null
            : _evidenceController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.curriculumRightsAction),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: l10n.curriculumRightsStatusLabel,
                ),
                items: [
                  for (final status in const [
                    'permission_pending',
                    'authorized',
                    'public_domain',
                    'restricted',
                  ])
                    DropdownMenuItem(
                      value: status,
                      child: Text(_rightsLabel(l10n, status)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _evidenceController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.curriculumRightsEvidenceLabel,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final uri = Uri.tryParse(value.trim());
                  return uri != null &&
                          uri.scheme == 'https' &&
                          uri.host.isNotEmpty
                      ? null
                      : l10n.curriculumHttpsRequired;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: l10n.curriculumReviewNoteLabel,
                ),
                validator: (value) => _requiredText(value, l10n),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.curriculumSaveRightsAction),
        ),
      ],
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.label,
    required this.requiredNote,
  });

  final String title;
  final String label;
  final bool requiredNote;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(labelText: widget.label),
          validator: (value) => widget.requiredNote
              ? _requiredText(value, l10n)
              : (value?.length ?? 0) > 2000
              ? l10n.curriculumNoteTooLong
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(l10n.confirmAction),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(label), visualDensity: VisualDensity.compact);
}

String? _requiredText(String? value, AppLocalizations l10n) =>
    value == null || value.trim().isEmpty ? l10n.requiredField : null;

int? _pageNumberFor(
  CurriculumImportItem item,
  List<CurriculumImportPage>? pages,
) {
  if (pages == null) return null;
  for (final page in pages) {
    if (page.id == item.importPageId) return page.pageNumber;
  }
  return null;
}

String _rightsLabel(AppLocalizations l10n, String status) => switch (status) {
  'unknown' => l10n.curriculumRightsUnknown,
  'permission_pending' => l10n.curriculumRightsPending,
  'authorized' => l10n.curriculumRightsAuthorized,
  'public_domain' => l10n.curriculumRightsPublicDomain,
  'restricted' => l10n.curriculumRightsRestricted,
  _ => status,
};
