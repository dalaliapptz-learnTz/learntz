import 'dart:convert';
import 'dart:io';

/// LearnTZ Design System 2.0 — Token Parity Validator
/// Verifies single source of truth across JSON, Flutter tokens, and Web CSS.
void main(List<String> args) {
  stdout.writeln('=== LearnTZ Design System 2.0: Token Parity Validation ===');

  final jsonFile = File('tokens/learntz_design_tokens.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln('Error: tokens/learntz_design_tokens.json not found!');
    exit(1);
  }

  final cssFile = File('web/css/learntz_design_tokens.css');
  if (!cssFile.existsSync()) {
    stderr.writeln('Error: web/css/learntz_design_tokens.css not found!');
    exit(1);
  }

  final dartTokensFile = File('lib/core/design_system/tokens/colors.dart');
  if (!dartTokensFile.existsSync()) {
    stderr.writeln('Error: lib/core/design_system/tokens/colors.dart not found!');
    exit(1);
  }

  final tokensJson = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
  final cssContent = cssFile.readAsStringSync();
  final dartContent = dartTokensFile.readAsStringSync();

  int assertions = 0;

  // Validate Brand Colors
  final brandColors = (tokensJson['color'] as Map<String, dynamic>)['brand'] as Map<String, dynamic>;
  for (final entry in brandColors.entries) {
    final hex = entry.value as String;
    final cleanHex = hex.replaceAll('#', '').toUpperCase();

    // Check Dart
    if (!dartContent.contains(cleanHex)) {
      stderr.writeln('Mismatch in Dart colors: missing hex $cleanHex for ${entry.key}');
      exit(1);
    }

    // Check CSS
    if (!cssContent.contains(hex)) {
      stderr.writeln('Mismatch in CSS colors: missing hex $hex for ${entry.key}');
      exit(1);
    }
    assertions += 2;
  }

  // Validate Semantic Colors
  final semanticColors = (tokensJson['color'] as Map<String, dynamic>)['semantic'] as Map<String, dynamic>;
  for (final entry in semanticColors.entries) {
    final group = entry.value as Map<String, dynamic>;
    for (final subEntry in group.entries) {
      final hex = subEntry.value as String;
      final cleanHex = hex.replaceAll('#', '').toUpperCase();
      if (!dartContent.contains(cleanHex)) {
        stderr.writeln('Mismatch in Dart semantic colors: missing $cleanHex (${entry.key}.${subEntry.key})');
        exit(1);
      }
      if (!cssContent.contains(hex)) {
        stderr.writeln('Mismatch in CSS semantic colors: missing $hex (${entry.key}.${subEntry.key})');
        exit(1);
      }
      assertions += 2;
    }
  }

  // Validate Spacing
  final spacingJson = tokensJson['spacing'] as Map<String, dynamic>;
  final spacingDartFile = File('lib/core/design_system/tokens/spacing.dart');
  if (spacingDartFile.existsSync()) {
    final dartSpacing = spacingDartFile.readAsStringSync();
    for (final entry in spacingJson.entries) {
      final value = entry.value;
      if (!dartSpacing.contains('$value.0')) {
        stderr.writeln('Mismatch in Dart spacing: missing $value.0 for ${entry.key}');
        exit(1);
      }
      assertions++;
    }
  }

  stdout.writeln('SUCCESS: All $assertions token assertions verified matching across JSON, Dart, and CSS!');
  exit(0);
}
