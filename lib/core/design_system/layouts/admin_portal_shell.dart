import 'package:flutter/material.dart';

import '../components/components.dart';
import '../tokens/design_tokens.dart';

class AdminNavGroup {
  const AdminNavGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<AdminNavItem> items;
}

class AdminNavItem {
  const AdminNavItem({
    required this.route,
    required this.label,
    required this.icon,
    this.badge,
  });

  final String route;
  final String label;
  final IconData icon;
  final String? badge;
}

/// LearnTZ Design System 2.0 — Admin & Staff Portal Shell Layout
/// Dense, efficient layout with role indicator and breadcrumbs navigation.
class AdminPortalShell extends StatefulWidget {
  const AdminPortalShell({
    required this.currentPath,
    required this.child,
    required this.groups,
    required this.onNavigate,
    super.key,
    this.roleBadge = 'Admin',
    this.staffEmail,
    this.breadcrumbs = const [],
    this.onSignOut,
  });

  final String currentPath;
  final Widget child;
  final List<AdminNavGroup> groups;
  final ValueChanged<String> onNavigate;
  final String roleBadge;
  final String? staffEmail;
  final List<String> breadcrumbs;
  final VoidCallback? onSignOut;

  @override
  State<AdminPortalShell> createState() => _AdminPortalShellState();
}

class _AdminPortalShellState extends State<AdminPortalShell> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isCompact = LearnTzBreakpoints.isCompact(context);

    if (isCompact) {
      // Mobile / Tablet Drawer Layout
      return Scaffold(
        backgroundColor: LearnTzColors.background,
        appBar: AppBar(
          title: const AppBrandLogo(height: 32),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AppBadge(
                label: widget.roleBadge,
                variant: AppBadgeVariant.primary,
                size: AppBadgeSize.sm,
              ),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: _buildSidebarContent(isCollapsed: false, inDrawer: true),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.breadcrumbs.isNotEmpty)
                _buildBreadcrumbsBar(),
              Expanded(child: widget.child),
            ],
          ),
        ),
      );
    }

    // Desktop Split-Pane Layout
    final sidebarWidth = _isSidebarCollapsed ? 76.0 : 260.0;

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: Row(
        children: [
          AnimatedContainer(
            duration: LearnTzMotion.durationFast,
            width: sidebarWidth,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: LearnTzColors.border)),
            ),
            child: _buildSidebarContent(isCollapsed: _isSidebarCollapsed),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: LearnTzSpacing.screenPadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: LearnTzSpacing.maxWideContentWidth,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: LearnTzColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                  size: 20,
                  color: LearnTzColors.textSecondary,
                ),
                onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              ),
              const SizedBox(width: 12),
              _buildBreadcrumbsBar(),
            ],
          ),
          Row(
            children: [
              AppBadge(
                label: widget.roleBadge,
                variant: AppBadgeVariant.primary,
                size: AppBadgeSize.md,
                icon: Icons.shield_outlined,
              ),
              if (widget.staffEmail != null) ...[
                const SizedBox(width: 12),
                Text(
                  widget.staffEmail!,
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (widget.onSignOut != null) ...[
                const SizedBox(width: 8),
                AppIconButton(
                  icon: Icons.logout_outlined,
                  tooltip: 'Sign Out',
                  size: 34,
                  onPressed: widget.onSignOut,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbsBar() {
    if (widget.breadcrumbs.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.breadcrumbs.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.chevron_right, size: 16, color: LearnTzColors.textSecondary),
            ),
          Text(
            widget.breadcrumbs[i],
            style: LearnTzTypography.caption.copyWith(
              fontWeight: i == widget.breadcrumbs.length - 1 ? FontWeight.w700 : FontWeight.w500,
              color: i == widget.breadcrumbs.length - 1 ? LearnTzColors.textPrimary : LearnTzColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSidebarContent({required bool isCollapsed, bool inDrawer = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: isCollapsed
              ? const Center(child: AppBrandLogo(height: 28))
              : const AppBrandLogo(height: 36),
        ),
        const Divider(height: 1, color: LearnTzColors.border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final group in widget.groups) ...[
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      group.title.toUpperCase(),
                      style: LearnTzTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                for (final item in group.items) _buildSidebarItem(item, isCollapsed, inDrawer),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(AdminNavItem item, bool isCollapsed, bool inDrawer) {
    final isSelected = widget.currentPath == item.route ||
        (item.route != '/admin' && widget.currentPath.startsWith(item.route));

    final fgColor = isSelected ? LearnTzColors.primary : LearnTzColors.textSecondary;
    final bgColor = isSelected ? LearnTzColors.primary50 : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: bgColor,
        borderRadius: LearnTzRadii.borderMd,
        child: InkWell(
          borderRadius: LearnTzRadii.borderMd,
          onTap: () {
            if (inDrawer) Navigator.of(context).pop();
            widget.onNavigate(item.route);
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: fgColor),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: LearnTzTypography.bodyRegular.copyWith(
                        color: isSelected ? LearnTzColors.primary : LearnTzColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.badge != null)
                    AppBadge(
                      label: item.badge!,
                      variant: isSelected ? AppBadgeVariant.primary : AppBadgeVariant.neutral,
                      size: AppBadgeSize.sm,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
