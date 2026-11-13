import 'package:flutter/material.dart';

import '../components/components.dart';
import '../tokens/design_tokens.dart';

class LearnerNavDestination {
  const LearnerNavDestination({
    required this.route,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badgeCount;
}

/// LearnTZ Design System 2.0 — Learner Role Shell Layout
/// Responsive shell providing child-safe, engaging navigation for students.
class LearnerShell extends StatelessWidget {
  const LearnerShell({
    required this.currentPath,
    required this.child,
    required this.destinations,
    required this.onNavigate,
    super.key,
    this.learnerName,
    this.streakDays,
    this.avatarPreset,
  });

  final String currentPath;
  final Widget child;
  final List<LearnerNavDestination> destinations;
  final ValueChanged<String> onNavigate;
  final String? learnerName;
  final int? streakDays;
  final String? avatarPreset;

  @override
  Widget build(BuildContext context) {
    final isCompact = LearnTzBreakpoints.isCompact(context);
    final selectedIndex = destinations.indexWhere(
      (d) => d.route == currentPath || (d.route != '/' && currentPath.startsWith(d.route)),
    );

    if (isCompact) {
      // Mobile Layout: Top app bar with streak + Bottom Navigation
      return Scaffold(
        backgroundColor: LearnTzColors.background,
        appBar: AppBar(
          title: const AppBrandLogo(height: 32),
          actions: [
            if (streakDays != null && streakDays! > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AppBadge(
                  label: '$streakDays Days',
                  icon: Icons.local_fire_department,
                  variant: AppBadgeVariant.accent,
                ),
              ),
            if (learnerName != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AppAvatar(
                  initials: learnerName!.substring(0, 1),
                  size: AppAvatarSize.sm,
                ),
              ),
          ],
        ),
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          onDestinationSelected: (index) => onNavigate(destinations[index].route),
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: d.badgeCount != null && d.badgeCount! > 0
                    ? Badge(label: Text('${d.badgeCount}'), child: Icon(d.icon))
                    : Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon ?? d.icon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    // Tablet & Desktop Layout: Left Navigation Rail + Expanded Content
    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            onDestinationSelected: (index) => onNavigate(destinations[index].route),
            leading: Column(
              children: [
                const SizedBox(height: 12),
                const AppBrandLogo(height: 36),
                const SizedBox(height: 16),
                if (streakDays != null && streakDays! > 0)
                  AppBadge(
                    label: '$streakDays',
                    icon: Icons.local_fire_department,
                    variant: AppBadgeVariant.accent,
                    size: AppBadgeSize.sm,
                  ),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppAvatar(
                    initials: learnerName != null && learnerName!.isNotEmpty
                        ? learnerName!.substring(0, 1)
                        : null,
                    size: AppAvatarSize.md,
                  ),
                ),
              ),
            ),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: d.badgeCount != null && d.badgeCount! > 0
                      ? Badge(label: Text('${d.badgeCount}'), child: Icon(d.icon))
                      : Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon ?? d.icon),
                  label: Text(d.label, style: LearnTzTypography.caption),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1, color: LearnTzColors.border),
          Expanded(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LearnTzSpacing.maxContentWidth,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
