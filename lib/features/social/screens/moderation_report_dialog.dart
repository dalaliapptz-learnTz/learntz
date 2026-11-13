import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../social_providers.dart';

class ModerationReportDialog extends ConsumerStatefulWidget {
  final String reporterLearnerId;
  final String targetType; // 'post' | 'comment' | 'channel_message' | 'learner_profile'
  final String targetId;
  final String? targetTitle;

  const ModerationReportDialog({
    super.key,
    required this.reporterLearnerId,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
  });

  @override
  ConsumerState<ModerationReportDialog> createState() =>
      _ModerationReportDialogState();
}

class _ModerationReportDialogState
    extends ConsumerState<ModerationReportDialog> {
  String _selectedReason = 'contact_sharing';
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(socialRepositoryProvider).reportContent(
            reporterLearnerId: widget.reporterLearnerId,
            targetType: widget.targetType,
            targetId: widget.targetId,
            reasonCategory: _selectedReason,
            details: _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thank you! Your safety report has been submitted to LearnTZ moderators.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Report Content'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Help keep LearnTZ safe for all learners. Reports are investigated by trained educational moderators.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason for report',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'contact_sharing',
                    child: Text('Sharing phone / email / external link'),
                  ),
                  DropdownMenuItem(
                    value: 'inappropriate_language',
                    child: Text('Inappropriate language'),
                  ),
                  DropdownMenuItem(
                    value: 'bullying_harassment',
                    child: Text('Bullying or unfriendly behaviour'),
                  ),
                  DropdownMenuItem(
                    value: 'non_educational',
                    child: Text('Non-educational spam or advertisement'),
                  ),
                  DropdownMenuItem(
                    value: 'misinformation',
                    child: Text('Factually incorrect academic content'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other concern'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedReason = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _detailsController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional details (Optional)',
                  hintText: 'Briefly explain why this content violates safety rules',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
