import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_card.dart';

/// LearnTZ Design System 2.0 — Canonical Enterprise Data Table
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.isLoading = false,
    this.emptyMessage = 'No records found',
    this.header,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final String emptyMessage;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppCard(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (rows.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            emptyMessage,
            style: LearnTzTypography.bodyRegular.copyWith(
              color: LearnTzColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            Padding(padding: LearnTzSpacing.cardPaddingDense, child: header!),
            const Divider(height: 1, color: LearnTzColors.border),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(LearnTzColors.neutral50),
                headingTextStyle: LearnTzTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LearnTzColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                dataTextStyle: LearnTzTypography.bodyRegular.copyWith(
                  color: LearnTzColors.textPrimary,
                ),
                dividerThickness: 1.0,
                horizontalMargin: 16,
                columnSpacing: 24,
                columns: columns,
                rows: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
