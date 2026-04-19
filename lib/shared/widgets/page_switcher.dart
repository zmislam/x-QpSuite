import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/page_switcher/providers/managed_pages_provider.dart';

/// A tappable chip that shows the active page name and opens a bottom sheet
/// to switch between managed pages. Typically placed in an AppBar.
class PageSwitcher extends StatelessWidget {
  const PageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final pagesProvider = context.watch<ManagedPagesProvider>();
    final activePage = pagesProvider.activePage;

    if (activePage == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showPagePicker(context, pagesProvider),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: activePage.profilePic != null
                ? NetworkImage(activePage.profilePicUrl)
                : null,
            child: activePage.profilePic == null
                ? Text(
                    activePage.pageName.isNotEmpty
                        ? activePage.pageName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              activePage.pageName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 20),
        ],
      ),
    );
  }

  void _showPagePicker(
      BuildContext context, ManagedPagesProvider pagesProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final pages = pagesProvider.pages;
        final activeId = pagesProvider.activePage?.id;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Switch Page',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...pages.map(
                (page) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: page.profilePic != null
                        ? NetworkImage(page.profilePicUrl)
                        : null,
                    child: page.profilePic == null
                        ? Text(page.pageName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(page.pageName),
                  subtitle: Text(page.category ?? ''),
                  trailing: page.id == activeId
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    pagesProvider.setActivePage(page);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
