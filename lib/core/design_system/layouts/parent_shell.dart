import 'package:flutter/material.dart';

import '../components/components.dart';
import '../tokens/design_tokens.dart';

class ParentNavDestination {
  const ParentNavDestination({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

class ChildSelectorOption {
  const ChildSelectorOption({
    required this.id,
    required this.fullName,
    required this.gradeLevel,
  });

  final String id;
  final String fullName;
  final String gradeLevel;
}

/// LearnTZ Design System 2.0 — Parent Role Shell Layout
/// Family cockpit supporting multi-child switcher and academic monitoring.
class ParentShell extends StatelessWidget {
  const ParentShell({
    required this.currentPath,
    required this.child,
    required this.destinations,
    required this.onNavigate,
    super.key,
    this.children = const [],
    this.selectedChildId,
    this.onSelectChild,
    this.onAddChild,
  });

  final String currentPath;
  final Widget child;
  final List<ParentNavDestination> destinations;
  final ValueChanged<String> onNavigate;
  final List<ChildSelectorOption> children;
  final String? selectedChildId;
  final ValueChanged<String>? onSelectChild;
  final VoidCallback? onAddChild;

  @override
  Widget build(BuildContext context) {
    final isCompact = LearnTzBreakpoints.isCompact(context);
    final selectedIndex = destinations.indexWhere(
      (d) => d.route == currentPath || (d.route != '/' && currentPath.startsWith(d.route)),
    );

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        title: const AppBrandLogo(height: 34),
        actions: [
          if (children.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: LearnTzColors.border),
                  borderRadius: LearnTzRadii.borderFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.face_outlined, size: 18, color: LearnTzColors.primary),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedChildId ?? children.first.id,
                        isDense: true,
                        style: LearnTzTypography.caption.copyWith(
                          color: LearnTzColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        items: [
                          for (final c in children)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.fullName} (${c.gradeLevel})'),
                            ),
                        ],
                        onChanged: (val) {
                          if (val != null && onSelectChild != null) {
                            onSelectChild!(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (onAddChild != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AppIconButton(
                icon: Icons.person_add_alt_1_outlined,
                tooltip: 'Add Child',
                size: 36,
                onPressed: onAddChild,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LearnTzSpacing.maxContentWidth,
            ),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: (isCompact && destinations.length >= 2)
          ? NavigationBar(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (index) => onNavigate(destinations[index].route),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            )
          : null,
    );
  }
}
